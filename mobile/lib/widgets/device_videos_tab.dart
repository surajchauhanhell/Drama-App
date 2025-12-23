import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/local_video_service.dart';
import '../screens/video_player_screen.dart';

class DeviceVideosTab extends StatefulWidget {
  final String searchQuery;
  
  const DeviceVideosTab({
    super.key, 
    this.searchQuery = '',
  });

  @override
  State<DeviceVideosTab> createState() => _DeviceVideosTabState();
}

class _DeviceVideosTabState extends State<DeviceVideosTab> with WidgetsBindingObserver {
  final LocalVideoService _localVideoService = LocalVideoService();
  
  // State
  AssetPathEntity? _currentFolder; // If null, showing folder list. If set, showing videos.
  List<AssetPathEntity> _folders = [];
  List<AssetEntity> _videos = [];
  bool _isLoading = true;
  bool _hasPermission = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFolders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permissions and reload folders when app comes to foreground
      _loadFolders();
    }
  }

  @override
  void didUpdateWidget(DeviceVideosTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
       setState(() {});
    }
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    
    // Check permission first
    final hasPerm = await _localVideoService.hasPermission();
    if (!hasPerm) {
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
      }
      return;
    }

    final folders = await _localVideoService.fetchVideoFolders();
    if (mounted) {
      setState(() {
        _hasPermission = true;
        _folders = folders;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVideos(AssetPathEntity folder) async {
    setState(() => _isLoading = true);
    final videos = await _localVideoService.fetchVideosFromFolder(folder);
    if (mounted) {
      setState(() {
        _currentFolder = folder;
        _videos = videos;
        _isLoading = false;
      });
    }
  }

  void _onBackToFolders() {
    setState(() {
      _currentFolder = null;
      _videos = [];
    });
  }

  Future<void> _showRenameDialog(AssetEntity video) async {
    final TextEditingController _renameController = TextEditingController(text: video.title);
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text("Rename Video", style: theme.textTheme.titleLarge),
        content: TextField(
          controller: _renameController,
          decoration: InputDecoration(
            hintText: "Enter new name",
            hintStyle: TextStyle(color: theme.disabledColor),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.disabledColor)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor)),
          ),
          style: theme.textTheme.bodyLarge,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: theme.disabledColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final newName = _renameController.text.trim();
              if (newName.isNotEmpty && newName != video.title) {
                final success = await _localVideoService.renameVideo(video, newName);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Video renamed successfully")),
                  );
                  // Refresh the current folder
                  if (_currentFolder != null) {
                    _loadVideos(_currentFolder!);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to rename video. File might be restricted.")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
            child: const Text("Rename", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(AssetEntity video) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text("Delete Video", style: theme.textTheme.titleLarge),
        content: Text("Are you sure you want to delete '${video.title}'?", style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: theme.disabledColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete", style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _localVideoService.deleteVideo(video);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video deleted")),
        );
        if (_currentFolder != null) {
          _loadVideos(_currentFolder!);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete video")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Permission Denied View
    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off, size: 60, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              "Permission required to access videos",
              style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await _localVideoService.openSettings();
                _loadFolders(); // Retry after returning
              },
              icon: const Icon(Icons.settings),
              label: const Text("Open Settings"),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // 1. VIDEOS VIEW (Inside a Folder)
    if (_currentFolder != null) {
      // Filter if search
      final filteredVideos = widget.searchQuery.isEmpty 
          ? _videos 
          : _videos.where((v) => (v.title ?? '').toLowerCase().contains(widget.searchQuery.toLowerCase())).toList();

      return Column(
        children: [
          // Folder Header / Back Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _onBackToFolders,
                ),
                Text(
                  _currentFolder!.name,
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredVideos.isEmpty
                ? Center(child: Text("No videos found", style: TextStyle(color: theme.disabledColor)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredVideos.length,
                    itemBuilder: (context, index) {
                      final video = filteredVideos[index];
                     return _LocalVideoCard(
                        video: video,
                        onTap: () async {
                           final file = await video.file;
                           if (file != null) {
                               Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoPlayerScreen(
                                      playlist: [{
                                        'title': video.title ?? 'Unknown',
                                        'url': file.path, 
                                        'isLocal': 'true'
                                      }],
                                      initialIndex: 0,
                                    ),
                                  ),
                                );
                           }
                        },
                        onRename: () => _showRenameDialog(video),
                        onDelete: () => _confirmDelete(video),
                      );
                    },
                  ),
          ),
        ],
      );
    }


    // 2. FOLDERS VIEW
    if (_folders.isEmpty) {
      return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_off, size: 60, color: theme.disabledColor),
              const SizedBox(height: 10),
              Text("No video folders found", style: TextStyle(color: theme.disabledColor)),
              const SizedBox(height: 8),
              Text(
                "Try recording a video or downloading one.",
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
      );
    }

    final filteredFolders = widget.searchQuery.isEmpty
        ? _folders
        : _folders.where((f) => f.name.toLowerCase().contains(widget.searchQuery.toLowerCase())).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: filteredFolders.length,
      itemBuilder: (context, index) {
        final folder = filteredFolders[index];
        return _FolderCard(
          folder: folder,
          onTap: () => _loadVideos(folder),
        );
      },
    );
  }
}

class _FolderCard extends StatelessWidget {
  final AssetPathEntity folder;
  final VoidCallback onTap;

  const _FolderCard({required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_copy, size: 50, color: theme.primaryColor),
            const SizedBox(height: 12),
            Text(
              folder.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
             FutureBuilder<int>(
              future: folder.assetCountAsync,
              builder: (context, snapshot) {
                 return Text(
                   '${snapshot.data ?? 0} Videos',
                   style: theme.textTheme.bodySmall,
                 );
              },
             ),
          ],
        ),
      ),
    );
  }
}

class _LocalVideoCard extends StatelessWidget {
  final AssetEntity video;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _LocalVideoCard({
    required this.video, 
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 90, 
      decoration: BoxDecoration(
         color: theme.colorScheme.surface,
         borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Thumbnail
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                child: Container(
                  color: Colors.black38,
                  child: FutureBuilder<Uint8List?>(
                    future: video.thumbnailData,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image.memory(snapshot.data!, fit: BoxFit.cover);
                      }
                      return const Center(child: Icon(Icons.play_circle_outline, color: Colors.white24));
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    video.title ?? 'Unknown Video',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatDuration(video.duration),
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
             // More menu icon
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              color: theme.cardColor,
              onSelected: (value) {
                if (value == 'rename') onRename();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20, color: theme.iconTheme.color),
                      const SizedBox(width: 8),
                      Text('Rename', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Text('Delete', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    if (duration.inHours == 0) {
       return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
    }
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }
}
