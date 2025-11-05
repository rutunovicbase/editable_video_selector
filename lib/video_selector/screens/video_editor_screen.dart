import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../models/video_file.dart';
import '../models/trim_data.dart';

/// Professional video editor view with custom frame-based trimmer
class VideoEditorScreen extends StatefulWidget {
  final VideoFile videoFile;
  final Duration maxDuration;
  final Duration minDuration;
  final bool enableHandleDrag;
  final bool enableMiddleDrag;

  const VideoEditorScreen({
    super.key,
    required this.videoFile,
    this.maxDuration = const Duration(seconds: 30),
    this.minDuration = const Duration(seconds: 1),
    this.enableHandleDrag = true,
    this.enableMiddleDrag = true,
  });

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  String? _error;

  Duration _startTime = Duration.zero;
  Duration _endTime = const Duration(seconds: 30);
  Duration _currentPosition = Duration.zero;

  final List<String?> _thumbnails = [];
  bool _isGeneratingThumbnails = false;

  static const int _thumbnailCount = 15; // More frames for smoother timeline

  // Improved dragging state for better performance
  bool _isDraggingStart = false;
  bool _isDraggingEnd = false;
  bool _isDraggingMiddle = false;
  double _trimmerWidth = 0;
  double _middleDragStartOffset = 0;
  Duration _middleDragStartTime = Duration.zero;
  Duration _middleDragEndTime = Duration.zero;

  // For smooth playback indicator
  Timer? _progressTimer;
  bool _wasPlayingBeforeDrag = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(File(widget.videoFile.path));
      await _controller!.initialize();

      final duration = _controller!.value.duration;

      setState(() {
        _isInitialized = true;

        // Initialize with minimum duration selection at the start
        _startTime = Duration.zero;
        _endTime = widget.minDuration;

        // Ensure we don't exceed video duration
        if (_endTime > duration) {
          _endTime = duration;
        }
      });

      debugPrint('📹 Video Editor initialized:');
      debugPrint('  Video duration: $duration');
      debugPrint('  Max duration: ${widget.maxDuration}');
      debugPrint('  Min duration: ${widget.minDuration}');
      debugPrint(
        '  Initial selection: $_startTime to $_endTime (${_endTime - _startTime})',
      );
      debugPrint('  Handle drag enabled: ${widget.enableHandleDrag}');
      debugPrint('  Middle drag enabled: ${widget.enableMiddleDrag}');

      _controller!.addListener(_videoListener);
      await _generateThumbnails();
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize video: $e';
      });
    }
  }

  void _videoListener() {
    if (!mounted) return;

    final position = _controller!.value.position;

    // Loop within trim range
    if (position >= _endTime) {
      _controller!.seekTo(_startTime);
    } else if (position < _startTime) {
      _controller!.seekTo(_startTime);
    }

    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _generateThumbnails() async {
    if (_isGeneratingThumbnails) return;

    setState(() {
      _isGeneratingThumbnails = true;
      _thumbnails.clear();
    });

    try {
      final duration = _controller!.value.duration;
      final interval = duration.inMilliseconds ~/ _thumbnailCount;

      for (int i = 0; i < _thumbnailCount; i++) {
        final timeMs = i * interval;

        // Ensure we don't request thumbnails beyond video duration
        final clampedTimeMs = timeMs.clamp(0, duration.inMilliseconds - 100);

        try {
          final thumbnail = await VideoThumbnail.thumbnailFile(
            video: widget.videoFile.path,
            thumbnailPath: (await getTemporaryDirectory()).path,
            imageFormat: ImageFormat.PNG,
            maxHeight: 80,
            timeMs: clampedTimeMs,
            quality: 75,
          );

          if (mounted) {
            setState(() {
              _thumbnails.add(thumbnail);
            });
          }
        } catch (e) {
          // Add null for failed thumbnails
          if (mounted) {
            setState(() {
              _thumbnails.add(null);
            });
          }
          debugPrint(
            '⚠️ Failed to generate thumbnail at ${clampedTimeMs}ms: $e',
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Thumbnail generation error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingThumbnails = false;
        });
      }
    }
  }

  void _updateStartTime(double position) {
    final duration = _controller!.value.duration;
    final newStart = Duration(
      milliseconds: (position * duration.inMilliseconds).toInt(),
    );

    // Calculate what the new duration would be
    final newDuration = _endTime - newStart;

    setState(() {
      // Check if new duration is within constraints
      if (newDuration < widget.minDuration) {
        // Would violate min duration - adjust end time to maintain min
        _startTime = newStart;
        _endTime = _startTime + widget.minDuration;

        // Ensure we don't exceed video bounds
        if (_endTime > duration) {
          _endTime = duration;
          _startTime = _endTime - widget.minDuration;
          if (_startTime < Duration.zero) _startTime = Duration.zero;
        }

        debugPrint(
          '� Start drag: Locked at MIN ${widget.minDuration} (tried ${newDuration})',
        );
      } else if (newDuration > widget.maxDuration) {
        // Would violate max duration - adjust end time to maintain max
        _startTime = newStart;
        _endTime = _startTime + widget.maxDuration;

        // Ensure we don't exceed video bounds
        if (_endTime > duration) {
          _endTime = duration;
          _startTime = _endTime - widget.maxDuration;
          if (_startTime < Duration.zero) _startTime = Duration.zero;
        }

        debugPrint(
          '🔒 Start drag: Locked at MAX ${widget.maxDuration} (tried ${newDuration})',
        );
      } else {
        // Within constraints - allow the change
        _startTime = newStart;
        debugPrint('✅ Start drag: ${_startTime} → duration: $newDuration');
      }
    });

    // Only seek if not playing to avoid stuttering
    if (!_controller!.value.isPlaying) {
      _controller!.seekTo(_startTime);
    }
  }

  void _updateEndTime(double position) {
    final duration = _controller!.value.duration;
    final newEnd = Duration(
      milliseconds: (position * duration.inMilliseconds).toInt(),
    );

    // Calculate what the new duration would be
    final newDuration = newEnd - _startTime;

    setState(() {
      // Check if new duration is within constraints
      if (newDuration < widget.minDuration) {
        // Would violate min duration - adjust start time to maintain min
        _endTime = newEnd;
        _startTime = _endTime - widget.minDuration;

        if (_startTime < Duration.zero) {
          _startTime = Duration.zero;
          _endTime = widget.minDuration;
        }

        debugPrint(
          '� End drag: Locked at MIN ${widget.minDuration} (tried ${newDuration})',
        );
      } else if (newDuration > widget.maxDuration) {
        // Would violate max duration - adjust start time to maintain max
        _endTime = newEnd;
        _startTime = _endTime - widget.maxDuration;

        if (_startTime < Duration.zero) {
          _startTime = Duration.zero;
          _endTime = widget.maxDuration;
        }

        debugPrint(
          '� End drag: Locked at MAX ${widget.maxDuration} (tried ${newDuration})',
        );
      } else {
        // Within constraints - allow the change
        _endTime = newEnd;
        debugPrint('✅ End drag: ${_endTime} → duration: $newDuration');
      }
    });
  }

  void _updateBothTimes(double deltaPosition) {
    final duration = _controller!.value.duration;
    final deltaMs = (deltaPosition * duration.inMilliseconds).toInt();
    final delta = Duration(milliseconds: deltaMs);

    final newStart = _middleDragStartTime + delta;
    final newEnd = _middleDragEndTime + delta;

    // Check boundaries
    if (newStart < Duration.zero || newEnd > duration) {
      return; // Don't update if it would go out of bounds
    }

    setState(() {
      _startTime = newStart;
      _endTime = newEnd;
    });

    // Only seek if not playing to avoid stuttering
    if (!_controller!.value.isPlaying) {
      _controller!.seekTo(_startTime);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _confirmTrim() {
    final trimData = TrimData(startTime: _startTime, endTime: _endTime);

    Navigator.of(context).pop(trimData);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Editor', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                _thumbnails.isEmpty
                    ? 'Loading video...'
                    : 'Generating frames ${_thumbnails.length}/$_thumbnailCount',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    final videoDuration = _controller!.value.duration;
    final trimDuration = _endTime - _startTime;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(),

            // Video preview
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),

            // Duration info
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatDuration(_startTime)} - ${_formatDuration(_endTime)}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '${_formatDuration(trimDuration)} / ${_formatDuration(widget.maxDuration)}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Custom frame-based trimmer
            _buildFrameTrimmer(videoDuration),

            // Playback controls
            _buildPlaybackControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text(
            'Edit Video',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: _confirmTrim,
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrameTrimmer(Duration videoDuration) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Timeline with thumbnails
          LayoutBuilder(
            builder: (context, constraints) {
              _trimmerWidth = constraints.maxWidth;
              final startPosition =
                  _startTime.inMilliseconds / videoDuration.inMilliseconds;
              final endPosition =
                  _endTime.inMilliseconds / videoDuration.inMilliseconds;

              return Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      // Thumbnail frames with improved performance
                      Row(
                        children: _thumbnails.isEmpty
                            ? List.generate(
                                _thumbnailCount,
                                (index) => Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 0.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        color: Colors.grey[600],
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : _thumbnails.map((thumbnail) {
                                if (thumbnail == null) {
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 0.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                }
                                return Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 0.5,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      image: DecorationImage(
                                        image: FileImage(File(thumbnail)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                      ),

                      // Overlay for non-selected areas with smooth animation
                      Positioned.fill(
                        child: Row(
                          children: [
                            // Left overlay (before start)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              curve: Curves.easeOut,
                              width: _trimmerWidth * startPosition,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.green.shade400,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            // Selected area (transparent)
                            Expanded(child: Container()),
                            // Right overlay (after end)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              curve: Curves.easeOut,
                              width: _trimmerWidth * (1 - endPosition),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.red.shade400,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Custom trim handles
                      _buildTrimHandles(startPosition, endPosition),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Time ruler
          _buildTimeRuler(videoDuration),
        ],
      ),
    );
  }

  Widget _buildTrimHandles(double startPosition, double endPosition) {
    final startLeft = _trimmerWidth * startPosition;
    final endLeft = _trimmerWidth * endPosition;
    final selectionWidth = endLeft - startLeft;

    return Stack(
      children: [
        // Selection highlight border (top and bottom)
        Positioned(
          left: startLeft,
          width: selectionWidth,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white, width: 3),
                bottom: BorderSide(color: Colors.white, width: 3),
              ),
            ),
          ),
        ),

        // Middle draggable section (if enabled)
        if (widget.enableMiddleDrag)
          Positioned(
            left: startLeft,
            width: selectionWidth,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) {
                setState(() {
                  _isDraggingMiddle = true;
                  _wasPlayingBeforeDrag = _controller!.value.isPlaying;
                  _middleDragStartOffset = details.globalPosition.dx;
                  _middleDragStartTime = _startTime;
                  _middleDragEndTime = _endTime;
                });
                if (_wasPlayingBeforeDrag) {
                  _controller!.pause();
                }
              },
              onHorizontalDragUpdate: (details) {
                final dx = details.globalPosition.dx;
                final deltaOffset = dx - _middleDragStartOffset;
                final deltaPosition = deltaOffset / _trimmerWidth;

                _updateBothTimes(deltaPosition);
              },
              onHorizontalDragEnd: (_) {
                setState(() {
                  _isDraggingMiddle = false;
                });
                if (_wasPlayingBeforeDrag && mounted) {
                  _controller!.play();
                }
              },
              child: Container(
                height: 80,
                color: Colors.transparent,
                child: Center(
                  child: Icon(
                    Icons.drag_indicator,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

        // Start handle with improved touch target
        if (widget.enableHandleDrag)
          Positioned(
            left: startLeft - 18,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) {
                setState(() {
                  _isDraggingStart = true;
                  _wasPlayingBeforeDrag = _controller!.value.isPlaying;
                });
                if (_wasPlayingBeforeDrag) {
                  _controller!.pause();
                }
              },
              onHorizontalDragUpdate: (details) {
                // Calculate position relative to timeline
                final dx =
                    details.globalPosition.dx -
                    20; // Account for container margin
                final newPosition = (dx / _trimmerWidth).clamp(0.0, 1.0);

                // Always update to enforce constraints properly
                _updateStartTime(newPosition);
              },
              onHorizontalDragEnd: (_) {
                setState(() {
                  _isDraggingStart = false;
                });
                if (_wasPlayingBeforeDrag && mounted) {
                  _controller!.play();
                }
              },
              child: Container(
                width: 36, // Larger touch target
                height: 80,
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(6),
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 3,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 3,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // End handle with improved touch target
        if (widget.enableHandleDrag)
          Positioned(
            left: endLeft - 18,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) {
                setState(() {
                  _isDraggingEnd = true;
                  _wasPlayingBeforeDrag = _controller!.value.isPlaying;
                });
                if (_wasPlayingBeforeDrag) {
                  _controller!.pause();
                }
              },
              onHorizontalDragUpdate: (details) {
                // Calculate position relative to timeline
                final dx =
                    details.globalPosition.dx -
                    20; // Account for container margin
                final newPosition = (dx / _trimmerWidth).clamp(0.0, 1.0);

                // Always update to enforce constraints properly
                _updateEndTime(newPosition);
              },
              onHorizontalDragEnd: (_) {
                setState(() {
                  _isDraggingEnd = false;
                });
                if (_wasPlayingBeforeDrag && mounted) {
                  _controller!.play();
                }
              },
              child: Container(
                width: 36, // Larger touch target
                height: 80,
                alignment: Alignment.centerRight,
                child: Container(
                  width: 20,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(6),
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 3,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 3,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Playhead indicator
        if (!_isDraggingStart &&
            !_isDraggingEnd &&
            !_isDraggingMiddle &&
            _controller!.value.isPlaying)
          Positioned(
            left:
                (_currentPosition.inMilliseconds /
                        _controller!.value.duration.inMilliseconds) *
                    _trimmerWidth -
                1,
            child: Container(
              width: 2,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeRuler(Duration videoDuration) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final time = (videoDuration.inSeconds / 6) * index;
        final duration = Duration(seconds: time.toInt());
        return Text(
          _formatDuration(duration),
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        );
      }),
    );
  }

  Widget _buildPlaybackControls() {
    return Container(
      padding: const EdgeInsets.only(bottom: 24, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Play/Pause button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () {
                setState(() {
                  if (_controller!.value.isPlaying) {
                    _controller!.pause();
                  } else {
                    if (_currentPosition < _startTime ||
                        _currentPosition >= _endTime) {
                      _controller!.seekTo(_startTime);
                    }
                    _controller!.play();
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
