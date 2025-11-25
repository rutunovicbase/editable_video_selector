import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/video_file.dart';

/// Configuration for camera recorder
class CameraRecorderConfig {
  final bool showCountdown;
  final int countdownSeconds;
  final bool enableZoom;
  final bool enableFlipCamera;
  final bool showZoomSlider;
  final bool requireConfirmation;
  final Duration? maxRecordingDuration;
  final ResolutionPreset quality;

  const CameraRecorderConfig({
    this.showCountdown = true,
    this.countdownSeconds = 3,
    this.enableZoom = true,
    this.enableFlipCamera = true,
    this.showZoomSlider = true,
    this.requireConfirmation = true,
    this.maxRecordingDuration,
    this.quality = ResolutionPreset.high,
  });

  factory CameraRecorderConfig.defaultConfig() => const CameraRecorderConfig();

  factory CameraRecorderConfig.professional() => const CameraRecorderConfig(
    showCountdown: true,
    countdownSeconds: 3,
    enableZoom: true,
    enableFlipCamera: true,
    showZoomSlider: true,
    requireConfirmation: true,
    quality: ResolutionPreset.veryHigh,
  );

  factory CameraRecorderConfig.simple() => const CameraRecorderConfig(
    showCountdown: false,
    countdownSeconds: 0,
    enableZoom: false,
    enableFlipCamera: false,
    showZoomSlider: false,
    requireConfirmation: false,
    quality: ResolutionPreset.medium,
  );
}

/// Professional camera recorder screen
class CameraRecorderScreen extends StatefulWidget {
  final CameraRecorderConfig config;

  const CameraRecorderScreen({
    super.key,
    this.config = const CameraRecorderConfig(),
  });

  @override
  State<CameraRecorderScreen> createState() => _CameraRecorderScreenState();
}

class _CameraRecorderScreenState extends State<CameraRecorderScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isCountingDown = false;
  int _countdown = 3;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  int _currentCameraIndex = 0;
  String? _error;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  bool _isFlashOn = false;
  double _lastScale = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupCamera(_currentCameraIndex);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _error = 'No cameras available';
        });
        return;
      }

      await _setupCamera(_currentCameraIndex);
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _setupCamera(int cameraIndex) async {
    if (_cameras == null || _cameras!.isEmpty) return;

    await _controller?.dispose();

    _controller = CameraController(
      _cameras![cameraIndex],
      widget.config.quality,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();

      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();

      // Start at min zoom but not less than 1.0
      _currentZoom = _minZoom.clamp(1.0, _maxZoom);
      await _controller!.setZoomLevel(_currentZoom);

      // Set flash mode to off by default
      await _controller!.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras == null ||
        _cameras!.length < 2 ||
        _isRecording ||
        !widget.config.enableFlipCamera)
      return;

    setState(() {
      _isInitialized = false;
    });

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    await _setupCamera(_currentCameraIndex);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });

      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      setState(() {
        _isFlashOn = !_isFlashOn; // Revert on error
      });
    }
  }

  Future<void> _startRecordingWithCountdown() async {
    if (_isRecording || _isCountingDown) return;

    if (widget.config.showCountdown && widget.config.countdownSeconds > 0) {
      setState(() {
        _isCountingDown = true;
        _countdown = widget.config.countdownSeconds;
      });

      for (int i = widget.config.countdownSeconds; i > 0; i--) {
        if (!mounted) return;
        setState(() {
          _countdown = i;
        });
        await Future.delayed(const Duration(seconds: 1));
      }

      if (!mounted) return;

      setState(() {
        _isCountingDown = false;
      });
    }

    await _startRecording();
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      // Start recording timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingSeconds++;
          });

          // Check max duration
          if (widget.config.maxRecordingDuration != null &&
              _recordingSeconds >=
                  widget.config.maxRecordingDuration!.inSeconds) {
            _stopRecording();
          }
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to start recording: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_isRecording) return;

    _recordingTimer?.cancel();

    try {
      final XFile videoFile = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });

      if (widget.config.requireConfirmation) {
        _showConfirmationScreen(videoFile.path);
      } else {
        _returnVideo(videoFile.path);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to stop recording: $e';
        _isRecording = false;
      });
    }
  }

  void _showConfirmationScreen(String videoPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoConfirmationScreen(
          videoPath: videoPath,
          onConfirm: () {
            Navigator.of(context).pop();
            _returnVideo(videoPath);
          },
          onRetake: () {
            Navigator.of(context).pop();
            // Delete the video file
            try {
              File(videoPath).deleteSync();
            } catch (e) {
              // Ignore deletion errors
            }
          },
        ),
      ),
    );
  }

  void _returnVideo(String videoPath) {
    final video = VideoFile(path: videoPath, createdAt: DateTime.now());
    if (mounted) {
      Navigator.of(context).pop(video);
    }
  }

  void _handleZoomChange(double value) {
    if (_controller == null || !widget.config.enableZoom) return;

    setState(() {
      _currentZoom = value;
    });
    _controller!.setZoomLevel(_currentZoom);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_controller == null || !widget.config.enableZoom) {
      return;
    }

    final double scale = details.scale;

    // Calculate zoom based on scale
    double newZoom = _currentZoom * (scale / _lastScale);
    newZoom = newZoom.clamp(_minZoom.clamp(1.0, _maxZoom), _maxZoom);

    if ((newZoom - _currentZoom).abs() > 0.01) {
      setState(() {
        _currentZoom = newZoom;
        _lastScale = scale;
      });
      _controller!.setZoomLevel(_currentZoom);
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _lastScale = 1.0;
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _lastScale = 1.0;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
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
          title: const Text('Camera', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _error = null;
                    });
                    _initializeCamera();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Initializing camera...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview with pinch to zoom

          GestureDetector(
            onScaleStart: widget.config.enableZoom ? _handleScaleStart : null,
            onScaleUpdate: widget.config.enableZoom ? _handleScaleUpdate : null,
            onScaleEnd: widget.config.enableZoom ? _handleScaleEnd : null,
            child: // Camera preview with pinch to zoom - Fixed 9:16 ratio
            GestureDetector(
              onScaleStart: widget.config.enableZoom ? _handleScaleStart : null,
              onScaleUpdate: widget.config.enableZoom ? _handleScaleUpdate : null,
              onScaleEnd: widget.config.enableZoom ? _handleScaleEnd : null,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),
          ),

          // Countdown overlay
          if (_isCountingDown)
            Container(
              color: Colors.black87,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.5, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Text(
                        '$_countdown',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 120,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close button
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),

                      // Center controls
                      Row(
                        children: [
                          // Flash toggle (only for back camera)
                          if (_currentCameraIndex == 0)
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              onPressed: _isRecording ? null : _toggleFlash,
                            ),

                          // Zoom indicator
                          if (widget.config.enableZoom)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${_currentZoom.toStringAsFixed(1)}x',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Flip camera button
                      if (widget.config.enableFlipCamera &&
                          _cameras != null &&
                          _cameras!.length > 1)
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.flip_camera_ios,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          onPressed: _isRecording ? null : _flipCamera,
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Recording indicator
          if (_isRecording)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 60),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pulsing dot
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.6, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                          onEnd: () {
                            // Trigger rebuild for continuous animation
                            if (mounted && _isRecording) {
                              setState(() {});
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(_recordingSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Zoom slider
          if (widget.config.enableZoom &&
              widget.config.showZoomSlider &&
              !_isCountingDown)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height * 0.3,
              bottom: MediaQuery.of(context).size.height * 0.3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _currentZoom,
                      min: _minZoom.clamp(1.0, _maxZoom),
                      max: _maxZoom,
                      onChanged: _handleZoomChange,
                    ),
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Record/Stop button
                      GestureDetector(
                        onTap: _isRecording
                            ? _stopRecording
                            : _startRecordingWithCountdown,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _isRecording ? 32 : 64,
                              height: _isRecording ? 32 : 64,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: _isRecording
                                    ? BoxShape.rectangle
                                    : BoxShape.circle,
                                borderRadius: _isRecording
                                    ? BorderRadius.circular(6)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Video confirmation screen with preview
class VideoConfirmationScreen extends StatefulWidget {
  final String videoPath;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;

  const VideoConfirmationScreen({
    super.key,
    required this.videoPath,
    required this.onConfirm,
    required this.onRetake,
  });

  @override
  State<VideoConfirmationScreen> createState() =>
      _VideoConfirmationScreenState();
}

class _VideoConfirmationScreenState extends State<VideoConfirmationScreen> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.file(File(widget.videoPath));
    await _videoController!.initialize();
    await _videoController!.setLooping(true);
    await _videoController!.play();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video preview
          if (_isInitialized && _videoController != null)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Preview Your Video',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),

          // Bottom buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Retake button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onRetake,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text(
                            'Retake',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Confirm button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onConfirm,
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text(
                            'Use Video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
