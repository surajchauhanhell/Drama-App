import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/drive_file.dart';

class DriveService {
  static const String apiKey = 'AIzaSyBnHPSdgv2Cc6wU38itY6YLriAb2g1_VQg';
  static const String folderId = '1qGzwJblLNfA9KBUlUzdXVa2mrw54lSbB';

  Future<List<DriveFile>> fetchFiles({String? folderId}) async {
    final targetFolderId = folderId ?? DriveService.folderId;
    final url = Uri.parse(
        'https://www.googleapis.com/drive/v3/files?q=\'$targetFolderId\'+in+parents+and+(mimeType+contains+\'video\'+or+mimeType+contains+\'image\'+or+mimeType+=+\'application/vnd.google-apps.folder\')&key=$apiKey&fields=files(id,name,mimeType)&orderBy=folder,name');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List files = data['files'];
        return files
            .map((json) => DriveFile.fromJson(json))
            .where((file) {
              // Double check filtering if needed, but API query should handle it
              return file.mimeType.contains('video') || 
                     file.mimeType.contains('image') || 
                     file.mimeType == 'application/vnd.google-apps.folder';
            }) 
            .toList();
      } else {
        throw Exception('Failed to load files: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching files: $e');
    }
  }

  String getVideoUrl(String fileId) {
    // Direct download URL for streaming
    return 'https://drive.google.com/uc?export=download&id=$fileId&confirm=t';
  }

  String getThumbnailUrl(String fileId) {
    return 'https://drive.google.com/uc?export=download&id=$fileId';
  }
}
