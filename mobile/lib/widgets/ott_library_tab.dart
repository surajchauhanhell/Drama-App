import 'package:flutter/material.dart';
import '../models/drive_file.dart';

import '../services/drive_service.dart';
import '../services/download_service.dart';
import '../screens/video_player_screen.dart';

class OttLibraryTab extends StatefulWidget {
  final String searchQuery;
  const OttLibraryTab({super.key, this.searchQuery = ''});

  @override
  State<OttLibraryTab> createState() => _OttLibraryTabState();
}

class _OttLibraryTabState extends State<OttLibraryTab> {
  final DriveService _driveService = DriveService();
  
  // Navigation Stack
  final List<DriveFile> _folderPath = [];
  
  // Current Folder Content
  late Future<List<DriveFile>> _filesFuture;
  
  // Current Folder Banner (if any image lies inside)
  String? _currentFolderBannerUrl;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  String? get _currentFolderId => _folderPath.isNotEmpty ? _folderPath.last.id : null;
  String get _currentFolderName => _folderPath.isNotEmpty ? _folderPath.last.name : 'Library';

  void _loadFiles() {
    setState(() {
      _currentFolderBannerUrl = null; // Reset banner
      _filesFuture = _driveService.fetchFiles(folderId: _currentFolderId).then((files) {
        // Post-processing to find banner
        final imageFile = files.firstWhere(
            (f) => f.mimeType.startsWith('image/'), 
            orElse: () => DriveFile(id: '', name: '', mimeType: ''));
        
        if (imageFile.id.isNotEmpty) {
          _currentFolderBannerUrl = _driveService.getThumbnailUrl(imageFile.id);
          // Remove ALL images from the list so they don't show as items
          // We only use the FIRST image as banner, and maybe hide others or hide all?
          // User said: "one image only that will be use as a folder banner... visible but banner... will be not visible in a app"
          // We'll hide ALL images to be safe/clean.
          return files.where((f) => !f.mimeType.startsWith('image/')).toList();
        }
        return files;
      });
    });
  }

  void _enterFolder(DriveFile folder) {
    _folderPath.add(folder);
    _loadFiles();
  }

  void _navigateBack() {
    if (_folderPath.isNotEmpty) {
      setState(() {
        _folderPath.removeLast();
        _loadFiles();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Intercept Back Button if in subfolder
    return PopScope(
      canPop: _folderPath.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigateBack();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb / Back Navigation Header
          if (_folderPath.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _navigateBack,
                  ),
                  Expanded(
                    child: Text(
                      _currentFolderName,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
          Expanded(
            child: FutureBuilder<List<DriveFile>>(
              future: _filesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  final error = snapshot.error;
                  final isNetworkError = error.toString().contains("SocketException") || 
                                         error.toString().contains("ClientException") || 
                                         error.toString().contains("Connection refused");

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isNetworkError ? Icons.wifi_off : Icons.error_outline,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isNetworkError ? 'No Internet Connection' : 'Oops! Something went wrong.',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadFiles,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: theme.disabledColor),
                        const SizedBox(height: 16),
                        Text('Empty Folder', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: _loadFiles,
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  );
                }

                final files = snapshot.data!;
                final filteredFiles = widget.searchQuery.isEmpty 
                    ? files 
                    : files.where((f) => f.name.toLowerCase().contains(widget.searchQuery.toLowerCase())).toList();
                    
                if (filteredFiles.isEmpty) {
                     return Center(child: Text("No items match your search", style: theme.textTheme.bodyMedium));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.70, // Taller for folder look
                  ),
                  itemCount: filteredFiles.length,
                  itemBuilder: (context, index) {
                    final file = filteredFiles[index];
                    final isFolder = file.mimeType == 'application/vnd.google-apps.folder';
                    
                    if (isFolder) {
                      return _FolderCard(
                        folder: file,
                        driveService: _driveService,
                        onTap: () => _enterFolder(file),
                      );
                    } else {
                       // Pass the CURRENT FOLDER's banner as the thumbnail for videos inside it
                      return _MovieCard(
                        file: file,
                        thumbnailUrl: _currentFolderBannerUrl,
                        onTap: () {
                          // Build playlist only from videos in this current view
                          final videoFiles = filteredFiles.where((f) => f.mimeType.contains('video')).toList();
                          final playlist = videoFiles.map((vFile) => {
                            'title': vFile.name,
                            'url': _driveService.getVideoUrl(vFile.id),
                          }).toList();
                          
                          // Find index in the VIDEO ONLY playlist
                          final videoIndex = videoFiles.indexOf(file);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(
                                playlist: playlist,
                                initialIndex: videoIndex,
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderCard extends StatefulWidget {
  final DriveFile folder;
  final DriveService driveService;
  final VoidCallback onTap;

  const _FolderCard({
    required this.folder, 
    required this.driveService, 
    required this.onTap
  });

  @override
  State<_FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<_FolderCard> {
  String? _bannerUrl;

  @override
  void initState() {
    super.initState();
    _fetchFolderBanner();
  }

  Future<void> _fetchFolderBanner() async {
    // Lazy fetch: Find first image inside this folder
    try {
      final files = await widget.driveService.fetchFiles(folderId: widget.folder.id);
      final image = files.firstWhere(
        (f) => f.mimeType.startsWith('image/'), 
        orElse: () => DriveFile(id: '', name: '', mimeType: '')
      );
      
      if (image.id.isNotEmpty && mounted) {
        setState(() {
          _bannerUrl = widget.driveService.getThumbnailUrl(image.id);
        });
      }
    } catch (_) {
      // Ignore errors for banner fetch
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: widget.onTap,
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
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image (Banner)
            if (_bannerUrl != null)
              Image.network(
                _bannerUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12),
              )
            else
              Container(
                color: theme.colorScheme.surfaceContainerHigh,
                child: Icon(Icons.folder, size: 48, color: theme.primaryColor.withOpacity(0.5)),
              ),

             // Overlay gradient for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // Folder Icon & Name
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                children: [
                  Icon(Icons.folder, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.folder.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  final DriveFile file;
  final String? thumbnailUrl;
  final VoidCallback onTap;

  const _MovieCard({
    required this.file, 
    this.thumbnailUrl,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
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
            // Thumbnail / Banner
            if (thumbnailUrl != null)
              Image.network(
                thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                   color: Colors.black12, 
                   child: const Center(child: Icon(Icons.movie, size: 40, color: Colors.white24))
                ),
              )
            else
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

            // Title Overlay
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
                child: Text(
                  file.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Download Button (Top Right)
            Positioned(
              top: 8,
              right: 8,
              child: _DownloadButton(file: file),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadButton extends StatefulWidget {
  final DriveFile file;
  const _DownloadButton({required this.file});

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  final DownloadService _downloadService = DownloadService();
  bool _isDownloading = false;
  double _progress = 0.0;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final downloads = await _downloadService.getDownloads();
    final isDownloaded = downloads.any((d) => d['id'] == widget.file.id);
    final isDownloading = _downloadService.isDownloading(widget.file.id);
    
    if (mounted) {
      setState(() {
        _isDownloaded = isDownloaded;
        _isDownloading = isDownloading;
        if (isDownloading) {
          _progress = _downloadService.getProgress(widget.file.id);
        }
      });
    }
  }

  Future<void> _startDownload() async {
    setState(() => _isDownloading = true);
    
    try {
      final driveService = DriveService();
      final url = driveService.getVideoUrl(widget.file.id);
      
      await _downloadService.downloadVideo(
        url: url,
        fileName: "${widget.file.name}.mp4",
        title: widget.file.name,
        driveId: widget.file.id,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.file.name} downloaded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDownloaded) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 16),
      );
    }

    if (_isDownloading) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(
            width: 24, 
            height: 24, 
            child: CircularProgressIndicator(
              value: _progress, 
              strokeWidth: 2, 
              color: Colors.white,
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _startDownload,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.download, color: Colors.white, size: 18),
      ),
    );
  }
}
