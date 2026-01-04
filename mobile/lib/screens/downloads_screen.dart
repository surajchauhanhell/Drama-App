import 'dart:io';
import 'package:flutter/material.dart';
import '../services/download_service.dart';
import 'video_player_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DownloadService _downloadService = DownloadService();
  List<Map<String, dynamic>> _downloads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    final downloads = await _downloadService.getDownloads();
    
    // Verify file existence
    final List<Map<String, dynamic>> validDownloads = [];
    for (var item in downloads) {
       final file = File(item['path']);
       if (await file.exists()) {
         validDownloads.add(item);
       } else {
         // Clean up metadata if file is missing (optional auto-cleanup)
         // For now, just don't show it or show as error
       }
    }

    if (mounted) {
      setState(() {
        _downloads = validDownloads;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDownload(String id) async {
    await _downloadService.deleteDownload(id);
    _loadDownloads();
  }

  void _playVideo(Map<String, dynamic> video, int index) {
      // Create playlist for VideoPlayerScreen
      // Since it's a local file, we pass "isLocal": "true"
      
      final playlist = _downloads.map((item) => {
        'title': item['title'] as String,
        'url': item['path'] as String,
        'isLocal': 'true', 
      }).toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            playlist: playlist,
            initialIndex: index,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Downloads'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _downloads.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 64, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text(
                        'No downloads yet', 
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _downloads.length,
                  itemBuilder: (context, index) {
                    final video = _downloads[index];
                    return Card(
                      color: theme.cardColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.play_circle_outline, color: Colors.white, size: 32),
                          ),
                        ),
                        title: Text(
                          video['title'],
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Downloaded on ${_formatDate(video['downloadedAt'])}',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _showDeleteConfirmation(video),
                        ),
                        onTap: () => _playVideo(video, index),
                      ),
                    );
                  },
                ),
    );
  }
  
  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    final date = DateTime.parse(isoString);
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteConfirmation(Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Download'),
        content: Text('Are you sure you want to delete "${video['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDownload(video['id']);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
