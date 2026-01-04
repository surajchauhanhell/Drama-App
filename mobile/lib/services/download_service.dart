import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio();
  final String _storageKey = 'downloaded_videos';
  
  // Track active downloads: driveId -> progress (0.0 to 1.0)
  final Map<String, double> _activeDownloads = {};
  // Track active cancel tokens
  final Map<String, CancelToken> _cancelTokens = {};

  Future<void> downloadVideo({
    required String url,
    required String fileName,
    required String title,
    required String driveId,
    Function(double)? onProgress,
  }) async {
    if (_activeDownloads.containsKey(driveId)) {
      throw Exception('Already downloading');
    }

    try {
      _activeDownloads[driveId] = 0.0;
      final cancelToken = CancelToken();
      _cancelTokens[driveId] = cancelToken;

      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$fileName';

      // 1. Resolve Final URL (handle virus warnings etc)
      final resolution = await _resolveUrlAndCookie(url);
      final finalUrl = resolution['url']!;
      final cookie = resolution['cookie'];

      // 2. Download using Dio with cookie
      await _dio.download(
        finalUrl,
        savePath,
        cancelToken: cancelToken,
        options: Options(
          headers: {
            if (cookie != null) 'Cookie': cookie,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          }
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _activeDownloads[driveId] = progress;
            if (onProgress != null) onProgress(progress);
          }
        },
      );

      // Save metadata
      await _saveMetadata(driveId: driveId, title: title, fileName: fileName, filePath: savePath);
      
      _activeDownloads.remove(driveId);
      _cancelTokens.remove(driveId);
      
    } catch (e) {
      _activeDownloads.remove(driveId);
      _cancelTokens.remove(driveId);
      rethrow;
    }
  }

  Future<Map<String, String?>> _resolveUrlAndCookie(String originalUrl) async {
    String currentUrl = originalUrl;
    String? currentCookie;
    final client = http.Client();
    
    for (int i = 0; i < 5; i++) {
        try {
           var request = http.Request('GET', Uri.parse(currentUrl))
             ..followRedirects = false;
             
           request.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
           
           if (currentCookie != null) {
              request.headers['cookie'] = currentCookie;
           }
           
           var response = await client.send(request);
           var location = response.headers['location'];
           String? newCookie = response.headers['set-cookie'];
           
           if (newCookie != null) {
             if (newCookie.contains(';')) {
                 newCookie = newCookie.split(';').first;
             }
             currentCookie = newCookie;
           }
           
           if ((response.statusCode == 302 || response.statusCode == 303) && location != null) {
              currentUrl = location;
              continue;
           } else if (response.statusCode == 200) {
               final contentType = response.headers['content-type'] ?? '';
               if (contentType.contains('text/html')) {
                   final body = await response.stream.bytesToString();
                   
                   final RegExp inputRegExp = RegExp(r'<input type="hidden" name="([^"]+)" value="([^"]+)">');
                   final matches = inputRegExp.allMatches(body);
                   var params = <String, String>{};
                   for (final m in matches) {
                       params[m.group(1)!] = m.group(2)!;
                   }
                   
                   final RegExp actionRegExp = RegExp(r'action="([^"]+)"');
                   final actionMatch = actionRegExp.firstMatch(body);
                   final actionUrl = actionMatch?.group(1);
                   
                   if (actionUrl != null && params.isNotEmpty) {
                        Uri uri;
                        if (actionUrl.startsWith('http')) {
                            uri = Uri.parse(actionUrl);
                        } else {
                            uri = Uri.parse(currentUrl).resolve(actionUrl);
                        }
                        // Important: Confirm action often needs POST or just query params on GET?
                        // Drive usually does GET for confirm.
                        currentUrl = uri.replace(queryParameters: params).toString();
                        continue;
                   }
               }
               
               client.close();
               return {
                   'url': currentUrl,
                   'cookie': currentCookie,
               };
           }
           
           break;
        } catch (e) {
           break;
        }
    }
    
    client.close();
    return {'url': currentUrl, 'cookie': currentCookie};
  }

  Future<void> _saveMetadata({
    required String driveId,
    required String title,
    required String fileName,
    required String filePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_storageKey);
    List<Map<String, dynamic>> downloads = [];
    
    if (existingJson != null) {
      downloads = List<Map<String, dynamic>>.from(json.decode(existingJson));
    }

    // Check if already exists (overwrite logic)
    final index = downloads.indexWhere((item) => item['id'] == driveId);
    final newItem = {
      'id': driveId,
      'title': title,
      'fileName': fileName,
      'path': filePath,
      'downloadedAt': DateTime.now().toIso8601String(),
    };

    if (index != -1) {
      downloads[index] = newItem;
    } else {
      downloads.add(newItem);
    }

    await prefs.setString(_storageKey, json.encode(downloads));
  }

  Future<List<Map<String, dynamic>>> getDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(jsonString));
  }

  Future<void> deleteDownload(String driveId) async {
    final prefs = await SharedPreferences.getInstance();
    final downloads = await getDownloads();
    final item = downloads.firstWhere((element) => element['id'] == driveId, orElse: () => {});
    
    if (item.isNotEmpty) {
      final file = File(item['path']);
      if (await file.exists()) {
        await file.delete();
      }
      
      downloads.removeWhere((element) => element['id'] == driveId);
      await prefs.setString(_storageKey, json.encode(downloads));
    }
  }

  bool isDownloading(String driveId) {
    return _activeDownloads.containsKey(driveId);
  }
  
  double getProgress(String driveId) {
    return _activeDownloads[driveId] ?? 0.0;
  }
}
