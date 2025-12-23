import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String apiKey = 'AIzaSyBnHPSdgv2Cc6wU38itY6YLriAb2g1_VQg';
  const String folderId = '1qGzwJblLNfA9KBUlUzdXVa2mrw54lSbB'; // The new ID

  print('Verifying access to Folder ID: $folderId');
  
  final url = Uri.parse(
        'https://www.googleapis.com/drive/v3/files?q=\'$folderId\'+in+parents+and+(mimeType+contains+\'video\'+or+mimeType+contains+\'image\'+or+mimeType+=+\'application/vnd.google-apps.folder\')&key=$apiKey&fields=files(id,name,mimeType)&orderBy=folder,name');

  try {
    print('Sending request to: $url');
    final response = await http.get(url);

    print('Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List files = data['files'];
      print('Found ${files.length} files.');
      for (var f in files) {
        print('FILE: ${f['name']} (${f['mimeType']})');
      }
      
      if (files.isEmpty) {
          print('WARNING: Folder is empty or contains no files accessible to this API key.');
      }
    } else {
      print('Error Body: ${response.body}');
    }
  } catch (e) {
    print('Exception: $e');
  }
}
