import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../models/video_file.dart';
import '../models/trim_data.dart';

/// Video trimmer screen with 30-second max trim and frame selection
class VideoTrimmerScreen extends StatefulWidget {
  final VideoFile videoFile;

  const VideoTrimmerScreen({super.key, required this.videoFile});

  @override
  State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
}

class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  String? _error;

  Duration _startTime = Duration.zero;
  Duration _endTime = const Duration(seconds: 30);
  Duration _currentPosition = Duration.zero;

  final List<String?> _thumbnails = [];
  bool _isGeneratingThumbnails = false;

  static const int _thumbnailCount = 10;
  static const Duration _maxTrimDuration = Duration(seconds: 30);

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
        _endTime = duration > _maxTrimDuration ? _maxTrimDuration : duration;
      });

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
      final videoFile = File(widget.videoFile.path);
      final fileSizeInMB = await videoFile.length() / (1024 * 1024);

      // For very long videos (>500MB or >10 min), generate thumbnails from first 3 minutes only
      final Duration effectiveDuration;
      if (fileSizeInMB > 500 || duration.inMinutes > 10) {
        effectiveDuration =
            Duration(minutes: 3).inMilliseconds < duration.inMilliseconds
            ? const Duration(minutes: 3)
            : duration;
        debugPrint(
          '📹 Large video (${fileSizeInMB.toStringAsFixed(1)}MB, ${duration.inMinutes}min) - generating thumbnails from first ${effectiveDuration.inSeconds}s',
        );
      } else {
        effectiveDuration = duration;
      }

      final interval = effectiveDuration.inMilliseconds ~/ _thumbnailCount;

      for (int i = 0; i < _thumbnailCount; i++) {
        if (!mounted) break;

        final timeMs = i * interval;
        final clampedTimeMs = timeMs.clamp(
          0,
          effectiveDuration.inMilliseconds - 100,
        );

        try {
          // Add timeout for thumbnail generation
          final thumbnail =
              await VideoThumbnail.thumbnailFile(
                video: widget.videoFile.path,
                thumbnailPath: (await getTemporaryDirectory()).path,
                imageFormat: ImageFormat.PNG,
                maxHeight: 100,
                timeMs: clampedTimeMs,
                quality: 75,
              ).timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  debugPrint(
                    '⏱️ Thumbnail generation timeout at ${clampedTimeMs}ms',
                  );
                  return null;
                },
              );

          // Verify thumbnail file exists and is valid
          if (thumbnail != null) {
            final thumbnailFile = File(thumbnail);

            // Retry logic - file might need time to be written
            bool isValid = false;
            for (int retry = 0; retry < 3; retry++) {
              if (!mounted) break;

              final exists = await thumbnailFile.exists();
              if (exists) {
                await Future.delayed(Duration(milliseconds: 50 * (retry + 1)));
                final size = await thumbnailFile.length();
                if (size > 0) {
                  isValid = true;
                  break;
                }
              }

              if (retry < 2) {
                await Future.delayed(Duration(milliseconds: 100));
              }
            }

            if (isValid && mounted) {
              setState(() {
                _thumbnails.add(thumbnail);
              });
            } else {
              debugPrint(
                '⚠️ Thumbnail file invalid or empty at ${clampedTimeMs}ms after retries',
              );
              if (mounted) {
                setState(() {
                  _thumbnails.add(null);
                });
              }
            }
          } else {
            if (mounted) {
              setState(() {
                _thumbnails.add(null);
              });
            }
          }
        } catch (e) {
          debugPrint(
            '⚠️ Failed to generate thumbnail at ${clampedTimeMs}ms: $e',
          );
          if (mounted) {
            setState(() {
              _thumbnails.add(null);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Thumbnail generation error: $e');
      // Fill remaining slots with nulls
      if (mounted) {
        final remaining = _thumbnailCount - _thumbnails.length;
        if (remaining > 0) {
          setState(() {
            _thumbnails.addAll(List.filled(remaining, null));
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingThumbnails = false;
        });
      }
    }
  }

  void _onTrimStart(double value) {
    final duration = _controller!.value.duration;
    final newStart = Duration(
      milliseconds: (value * duration.inMilliseconds).toInt(),
    );

    setState(() {
      _startTime = newStart;

      // Ensure end time is at least start time
      if (_endTime <= _startTime) {
        _endTime = _startTime + const Duration(seconds: 1);
      }

      // Ensure trim duration doesn't exceed max
      if (_endTime - _startTime > _maxTrimDuration) {
        _endTime = _startTime + _maxTrimDuration;
      }
    });

    _controller!.seekTo(_startTime);
  }

  void _onTrimEnd(double value) {
    final duration = _controller!.value.duration;
    final newEnd = Duration(
      milliseconds: (value * duration.inMilliseconds).toInt(),
    );

    setState(() {
      _endTime = newEnd;

      // Ensure start time is before end time
      if (_startTime >= _endTime) {
        _startTime = _endTime - const Duration(seconds: 1);
      }

      // Ensure trim duration doesn't exceed max
      if (_endTime - _startTime > _maxTrimDuration) {
        _startTime = _endTime - _maxTrimDuration;
      }
    });
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
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Video Trimmer')),
        body: Center(child: Text(_error!)),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Video Trimmer')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final videoDuration = _controller!.value.duration;
    final trimDuration = _endTime - _startTime;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Trim Video', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _confirmTrim,
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.blue, fontSize: 18),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Video player
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
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
                  'Trim Duration: ${_formatDuration(trimDuration)} / ${_formatDuration(_maxTrimDuration)}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDuration(_startTime)} - ${_formatDuration(_endTime)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Thumbnail timeline
          Container(
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: _thumbnails.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : Row(
                    children: _thumbnails.map((thumbnail) {
                      if (thumbnail == null) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            color: Colors.grey[800],
                          ),
                        );
                      }
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          child: Image.file(
                            File(thumbnail),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('❌ Error loading thumbnail: $error');
                              return Container(
                                color: Colors.grey[800],
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey[600],
                                  size: 16,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),

          // Trim sliders
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Start trim slider
                Row(
                  children: [
                    const Icon(
                      Icons.content_cut,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.green,
                          inactiveTrackColor: Colors.grey,
                          thumbColor: Colors.green,
                          overlayColor: Colors.green.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value:
                              _startTime.inMilliseconds /
                              videoDuration.inMilliseconds,
                          min: 0.0,
                          max: 1.0,
                          onChanged: _onTrimStart,
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(_startTime),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),

                // End trim slider
                Row(
                  children: [
                    const Icon(
                      Icons.content_cut,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.red,
                          inactiveTrackColor: Colors.grey,
                          thumbColor: Colors.red,
                          overlayColor: Colors.red.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value:
                              _endTime.inMilliseconds /
                              videoDuration.inMilliseconds,
                          min: 0.0,
                          max: 1.0,
                          onChanged: _onTrimEnd,
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(_endTime),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Playback controls
          Container(
            padding: const EdgeInsets.only(bottom: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _controller!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
