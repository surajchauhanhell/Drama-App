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
  bool _isLoading = true;
  String? _selectedFolder; // Null means "All Folders" view, Value means "This Folder" view

  // Map<FolderName, List<VideoData>>
  Map<String, List<Map<String, dynamic>>> _groupedDownloads = {};

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    final downloads = await _downloadService.getDownloads();
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var item in downloads) {
      // Verify file existence (optional but good for cleanup)
      final file = File(item['path']);
      if (await file.exists()) {
        final folderName = item['folderName'] ?? 'Unknown Series';
        grouped.putIfAbsent(folderName, () => []);
        grouped[folderName]!.add(item);
      }
    }

    if (mounted) {
      setState(() {
        _groupedDownloads = grouped;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDownload(String id) async {
    await _downloadService.deleteDownload(id);
    _loadDownloads();
  }

  void _playVideo(List<Map<String, dynamic>> contextVideos, int index) {
      final playlist = contextVideos.map((item) => {
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

  void _onBackPressed() {
    if (_selectedFolder != null) {
      setState(() => _selectedFolder = null);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine title
    String title = 'Downloads';
    if (_selectedFolder != null) {
      title = _selectedFolder!;
    }

    return WillPopScope(
      onWillPop: () async {
        if (_selectedFolder != null) {
          setState(() => _selectedFolder = null);
          return false; // Don't exit app/screen
        }
        return true; // Exit screen
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onBackPressed,
          ),
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _groupedDownloads.isEmpty
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
                : _selectedFolder == null
                    ? _buildFolderGrid(theme)
                    : _buildEpisodesGrid(theme),
      ),
    );
  }

  Widget _buildFolderGrid(ThemeData theme) {
    // Sort folders by name or recent activity? Default to alphabetical for now
    final folderNames = _groupedDownloads.keys.toList()..sort();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85, 
      ),
      itemCount: folderNames.length,
      itemBuilder: (context, index) {
        final folderName = folderNames[index];
        final videoCount = _groupedDownloads[folderName]?.length ?? 0;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedFolder = folderName;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder, size: 48, color: theme.primaryColor),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    folderName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$videoCount items',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEpisodesGrid(ThemeData theme) {
    final videos = _groupedDownloads[_selectedFolder] ?? [];
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.70,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return GestureDetector(
          onTap: () => _playVideo(videos, index),
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
                // Placeholder Gradient
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Delete Button
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
    );
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
