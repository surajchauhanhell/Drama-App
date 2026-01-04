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
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: _downloads.length,
                  itemBuilder: (context, index) {
                    final video = _downloads[index];
                    return GestureDetector(
                      onTap: () => _playVideo(video, index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Placeholder Gradient (since we don't save thumbnails yet)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.colorScheme.surface,
                                    theme.colorScheme.surface.withOpacity(0.5),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.movie, size: 40, color: Colors.white24),
                              ),
                            ),
                            
                            // Play Button
                            Center(
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                              ),
                            ),

                            // Text Overlay
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Title (Episode)
                                    Text(
                                      video['title'] ?? 'Unknown',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    // Subtitle (Series Name)
                                    Text(
                                      video['folderName'] ?? 'Unknown Series',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: Colors.white70,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Delete Button (Top Right)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => _showDeleteConfirmation(video),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
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
