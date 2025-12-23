import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoPlayerScreen extends StatefulWidget {
  final List<Map<String, String>> playlist;
  final int initialIndex;

  const VideoPlayerScreen({
    Key? key,
    required this.playlist,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  Timer? _hideTimer;
  String? _seekAction;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLocked = false;
  Timer? _saveProgressTimer;

  // Quality State
  String _currentQuality = 'Auto';
  final List<String> _qualities = ['Auto', '1080p', '720p', '480p', '360p'];

  // Gesture Control State
  double _volume = 0.5;
  double _brightness = 0.5;
  bool _isAdjustingVolume = false;
  bool _isAdjustingBrightness = false;
  
  // Recommendation State
  bool _showRecommendationsOverlay = false;
  late int _currentEpisodeIndex; 

  @override
  void initState() {
    super.initState();
    _currentEpisodeIndex = widget.initialIndex;
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Immersive mode only for landscape, will handle in build
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    _initializePlayer();
    _initializeGestureControls();
  }

  Future<void> _initializeGestureControls() async {
    try {
      _volume = await FlutterVolumeController.getVolume() ?? 0.5;
      _brightness = await ScreenBrightness().current;
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing gesture controls: $e');
    }
  }

  Future<void> _initializePlayer() async {
    try {
      final currentVideo = widget.playlist[_currentEpisodeIndex];
      // Check if it's a local video
      if (currentVideo['isLocal'] == 'true') {
        _controller = VideoPlayerController.file(
          File(currentVideo['url']!),
        );
      } else {
        // Existing Network Logic
        final result = await _resolveUrlAndCookie(currentVideo['url']!);
        final finalUrl = result['url']!;
        final cookie = result['cookie'];
        
        final Map<String, String> headers = {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        };
        
        if (cookie != null) {
          headers['Cookie'] = cookie;
        }

        _controller = VideoPlayerController.networkUrl(
          Uri.parse(finalUrl),
          httpHeaders: headers,
        );
      }
      
      await _controller.initialize().timeout(const Duration(seconds: 15));
      
      setState(() {
        _isLoading = false;
      });

      _checkSavedProgress();
      _startSaveProgressTimer();

      _controller.play();
      _startHideTimer();
      
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load video. Please check your internet or file permissions.\nDetailed error: $e';
        });
      }
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
           debugPrint('Error resolving url: $e');
           break;
        }
    }
    
    client.close();
    return {'url': currentUrl, 'cookie': currentCookie};
  }

  @override
  void dispose() {
    if (!_isLoading && _errorMessage == null) {
        _controller.dispose();
    }
    _hideTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    try {
      ScreenBrightness().resetScreenBrightness();
    } catch (_) {}
    _saveProgress();
    _saveProgressTimer?.cancel();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    }
  }



  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      if (_isLocked) {
        _showControls = false;
      } else {
        _showControls = true;
        _startHideTimer();
      }
    });
  }

  Future<void> _checkSavedProgress() async {
    try {
        final prefs = await SharedPreferences.getInstance();
        final videoUrl = widget.playlist[_currentEpisodeIndex]['url'];
        if (videoUrl == null) return;
        
        final savedPosition = prefs.getInt('video_progress_$videoUrl');
        if (savedPosition != null && savedPosition > 5000) { // Only resume if > 5 seconds
            final position = Duration(milliseconds: savedPosition);
            final duration = _controller.value.duration;
            
            if (duration.inMilliseconds - position.inMilliseconds > 10000) { // And not near the end
                if (!mounted) return;
                _controller.pause();
                showDialog(
                  context: context, 
                  builder: (ctx) => AlertDialog(
                    title: const Text('Resume Playback?', style: TextStyle(color: Colors.black)),
                    backgroundColor: Colors.white,
                    content: Text('Would you like to resume from ${_formatDuration(position)}?', style: const TextStyle(color: Colors.black87)),
                    actions: [
                        TextButton(
                            onPressed: () {
                                Navigator.of(ctx).pop();
                                _controller.seekTo(Duration.zero);
                                _controller.play();
                            }, 
                            child: const Text('Start Over'),
                        ),
                        TextButton(
                            onPressed: () {
                                Navigator.of(ctx).pop();
                                _controller.seekTo(position);
                                _controller.play();
                            }, 
                            child: const Text('Resume'),
                        ),
                    ],
                  ),
                );
            }
        }
    } catch (e) {
        debugPrint('Error checking saved progress: $e');
    }
  }

  void _startSaveProgressTimer() {
      _saveProgressTimer?.cancel();
      _saveProgressTimer = Timer.periodic(const Duration(seconds: 5), (_) => _saveProgress());
  }

  Future<void> _saveProgress() async {
      if (!_controller.value.isInitialized || !_controller.value.isPlaying) return;
      try {
          final prefs = await SharedPreferences.getInstance();
          final videoUrl = widget.playlist[_currentEpisodeIndex]['url'];
           if (videoUrl != null) {
               await prefs.setInt('video_progress_$videoUrl', _controller.value.position.inMilliseconds);
           }
      } catch (e) {
          debugPrint('Error saving progress: $e');
      }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isInitialized && _controller.value.isPlaying) {
         setState(() {
           _showControls = false;
         });
      }
    });
  }

  void _seek(int seconds) {
    if (_isLoading || _errorMessage != null || !_controller.value.isInitialized) return;
    final newPos = _controller.value.position + Duration(seconds: seconds);
    _controller.seekTo(newPos);
    
    setState(() {
      _seekAction = seconds > 0 ? 'forward' : 'backward';
      _showControls = true;
    });
    _startHideTimer();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _seekAction = null;
        });
      }
    });
  }

  void _toggleFullscreen() {
      final orientation = MediaQuery.of(context).orientation;
      if (orientation == Orientation.portrait) {
          SystemChrome.setPreferredOrientations([
             DeviceOrientation.landscapeLeft,
             DeviceOrientation.landscapeRight,
          ]);
      } else {
          SystemChrome.setPreferredOrientations([
             DeviceOrientation.portraitUp,
             DeviceOrientation.portraitDown,
          ]);
      }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _showQualitySettings() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quality',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ..._qualities.map((quality) {
                final isSelected = _currentQuality == quality;
                return ListTile(
                  leading: isSelected
                      ? Icon(Icons.check, color: theme.primaryColor)
                      : const SizedBox(width: 24),
                  title: Text(
                    quality,
                    style: TextStyle(
                      color: isSelected ? theme.primaryColor : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                       _currentQuality = quality;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         content: Text('Quality set to $quality (Simulation)'),
                         backgroundColor: theme.cardTheme.color,
                         behavior: SnackBarBehavior.floating,
                       ),
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
            return _buildLandscapeLayout(context, theme);
          } else {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            return _buildPortraitLayout(context, theme);
          }
        },
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        SafeArea(
          child: _isLoading || _errorMessage != null
              ? AspectRatio(
                  aspectRatio: 16/9,
                  child: _errorMessage != null 
                     ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)))
                     : Container(color: Colors.black, child: Center(child: CircularProgressIndicator(color: theme.primaryColor))),
                )
              : AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: _buildVideoPlayer(context, theme),
                ),
        ),
        Expanded(
          child: Container(
            color: theme.scaffoldBackgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Recommended Episodes',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.playlist.length,
                    itemBuilder: (context, index) {
                      final isPlaying = index == _currentEpisodeIndex;
                      final episode = widget.playlist[index];
                      return ListTile(
                        selected: isPlaying,
                        selectedTileColor: theme.primaryColor.withOpacity(0.1),
                        leading: Container(
                          width: 80,
                          height: 45,
                          color: Colors.grey[800],
                          child: Center(
                            child: isPlaying 
                                ? Icon(Icons.equalizer, color: theme.primaryColor)
                                : const Icon(Icons.play_arrow, color: Colors.white),
                          ),
                        ),
                        title: Text(
                            episode['title']!,
                            style: TextStyle(
                                color: isPlaying ? theme.primaryColor : Colors.white,
                                fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                            ),
                        ),
                        subtitle: isPlaying 
                            ? Text('Now Playing', style: TextStyle(color: theme.primaryColor.withOpacity(0.7)))
                            : null,
                        onTap: () {
                          if (_currentEpisodeIndex == index) return; // Already playing
                          
                          setState(() {
                              _currentEpisodeIndex = index;
                              _isLoading = true; 
                              _errorMessage = null;
                          });
                          
                          // Dispose old controller if needed and re-initialize
                          _controller.dispose();
                          _initializePlayer();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, ThemeData theme) {
    return Stack(
      children: [
         Center(
          child: _isLoading || _errorMessage != null
              ? AspectRatio(
                  aspectRatio: 16/9,
                  child: _errorMessage != null 
                     ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)))
                     : Container(color: Colors.black, child: Center(child: CircularProgressIndicator(color: theme.primaryColor))),
                )
              : AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: _buildVideoPlayer(context, theme),
                ),
        ),
        
        // Gesture for Overlay
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 50, // Edge trigger area
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < 0) { // Swipe Left to show
                setState(() {
                  _showRecommendationsOverlay = true;
                });
              }
            },
            behavior: HitTestBehavior.translucent,
          ),
        ),

        // Recommendations Overlay
        if (_showRecommendationsOverlay)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 300,
            child: Container(
              color: Colors.black.withOpacity(0.9),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Episodes',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _showRecommendationsOverlay = false;
                          });
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.playlist.length,
                      itemBuilder: (context, index) {
                         final episode = widget.playlist[index];
                         final isPlaying = index == _currentEpisodeIndex;
                         return ListTile(
                          leading: Container(
                            width: 80,
                            height: 45,
                            color: Colors.grey[800],
                            child: const Center(child: Icon(Icons.play_arrow, color: Colors.white)),
                          ),
                          title: Text(episode['title']!, style: TextStyle(color: isPlaying ? theme.primaryColor : Colors.white)),
                          onTap: () {
                             if (_currentEpisodeIndex == index) return;

                             setState(() {
                                 _currentEpisodeIndex = index;
                                 _isLoading = true;
                                 _errorMessage = null;
                                 _showRecommendationsOverlay = false; // Close overlay
                             });
                             
                             _controller.dispose();
                             _initializePlayer();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoPlayer(BuildContext context, ThemeData theme) {
    return GestureDetector(
        onTap: () {
          if (_isLocked) {
             setState(() {
                 _showControls = !_showControls; // Toggle unlock button visibility
             });
          } else {
             _toggleControls();
          }
        },
        onVerticalDragStart: (details) {
          if (_isLocked) return;
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            setState(() {
              _isAdjustingBrightness = true;
            });
          } else {
            setState(() {
              _isAdjustingVolume = true;
            });
          }
        },
        onVerticalDragUpdate: (details) async {
          if (_isAdjustingBrightness) {
            final delta = -details.delta.dy / 200; // Sensitivity 
            _brightness = (_brightness + delta).clamp(0.0, 1.0);
            try {
              await ScreenBrightness().setScreenBrightness(_brightness);
            } catch (_) {}
            setState(() {});
          } else if (_isAdjustingVolume) {
             final delta = -details.delta.dy / 200;
             _volume = (_volume + delta).clamp(0.0, 1.0);
             try {
                await FlutterVolumeController.setVolume(_volume);
             } catch (_) {}
             setState(() {});
          }
        },
        onVerticalDragEnd: (_) {
          setState(() {
            _isAdjustingBrightness = false;
            _isAdjustingVolume = false;
          });
        },
        onDoubleTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            _seek(-10);
          } else {
            _seek(10);
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: _isLoading
                  ? CircularProgressIndicator(color: theme.primaryColor)
                  : _errorMessage != null
                      ? Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
                               const SizedBox(height: 10),
                               Text(
                                 _errorMessage!,
                                 style: const TextStyle(color: Colors.white),
                                 textAlign: TextAlign.center,
                               ),
                               const SizedBox(height: 20),
                               ElevatedButton(
                                 onPressed: () {
                                   setState(() {
                                     _isLoading = true;
                                     _errorMessage = null;
                                   });
                                   _initializePlayer();
                                 },
                                 child: const Text('Retry'),
                               ),
                             ],
                          ),
                        )
                      : AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
            ),
            
            // Seek Animation
            if (_seekAction != null)
              Positioned(
                left: _seekAction == 'backward' ? 50 : null,
                right: _seekAction == 'forward' ? 50 : null,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _seekAction == 'forward' ? Icons.fast_forward : Icons.fast_rewind,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _seekAction == 'forward' ? '+10s' : '-10s',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                    ),
                  ),
              ),

            // Brightness/Volume Overlay
            if (_isAdjustingBrightness || _isAdjustingVolume)
              Center(
                 child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isAdjustingBrightness 
                              ? Icons.brightness_6 
                              : (_volume == 0 ? Icons.volume_off : Icons.volume_up),
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 150,
                          child: LinearProgressIndicator(
                            value: _isAdjustingBrightness ? _brightness : _volume,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                          ),
                        ),
                        const SizedBox(height: 8),
                         Text(
                          '${((_isAdjustingBrightness ? _brightness : _volume) * 100).toInt()}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ),

            // Controls Overlay
            if (_showControls && !_isLoading && _errorMessage == null)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black87,
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black87,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
                child: Column(
                  children: [
                    // Top Bar
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            Expanded(
                              child: Text(
                                widget.playlist[_currentEpisodeIndex]['title']!,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white, 
                                  shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Center Play/Pause
                    IconButton(
                      iconSize: 56,
                      icon: Icon(
                        _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: theme.primaryColor,
                      ),
                      onPressed: () {
                        if (_isLoading || _errorMessage != null) return;
                        setState(() {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                          _startHideTimer();
                        });
                      },
                    ),

                    const Spacer(),

                    // Bottom Bar
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_controller.value.position),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                Row(
                              children: [
                                      IconButton(
                                       icon: const Icon(Icons.settings, color: Colors.white),
                                       onPressed: _showQualitySettings,
                                     ),
                                     IconButton(
                                       icon: Icon(_isLocked ? Icons.lock : Icons.lock_open, color: Colors.white),
                                       onPressed: _toggleLock,
                                     ),
                                    Text(
                                      _formatDuration(_controller.value.duration),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                       icon: const Icon(Icons.fullscreen, color: Colors.white),
                                       onPressed: _toggleFullscreen,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              colors: VideoProgressColors(
                                playedColor: theme.primaryColor,
                                bufferedColor: Colors.white24,
                                backgroundColor: Colors.white10,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Locked Overlay
            if (_isLocked && _showControls)
                Center(
                    child: GestureDetector(
                        onTap: _toggleLock,
                        child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white30),
                            ),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                    Icon(Icons.lock_open, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Tap to Unlock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                            ),
                        ),
                    ),
                ),
          ],
        ),
      );
  }
}
