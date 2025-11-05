import 'package:flutter/material.dart';
import 'package:editable_video_picker/video_selector.dart';
import 'dart:io';

void main() {
  runApp(const VideoSelectorExample());
}

class VideoSelectorExample extends StatelessWidget {
  const VideoSelectorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Selector Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const VideoPickerDemo(),
    );
  }
}

class VideoPickerDemo extends StatefulWidget {
  const VideoPickerDemo({super.key});

  @override
  State<VideoPickerDemo> createState() => _VideoPickerDemoState();
}

class _VideoPickerDemoState extends State<VideoPickerDemo> {
  File? _selectedVideoFile;
  VideoPickerConfig _currentConfig = VideoPickerConfig.defaultConfig();
  bool _isProcessing = false;

  Future<void> _pickVideo(VideoSource source) async {
    setState(() {
      _isProcessing = true;
      _selectedVideoFile = null;
    });

    try {
      final File? videoFile = await VideoPicker.pickVideo(
        context: context,
        source: source,
        config: _currentConfig,
      );

      if (videoFile != null && mounted) {
        setState(() {
          _selectedVideoFile = videoFile;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video ready: ${videoFile.path}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Video Selector Example'),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.video_library, size: 80, color: Colors.blue),
                  const SizedBox(height: 24),
                  const Text(
                    'Video Selector Package',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 48),

                  ElevatedButton.icon(
                    onPressed: () => _pickVideo(VideoSource.camera),
                    icon: const Icon(Icons.videocam),
                    label: const Text('Record from Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: () => _pickVideo(VideoSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick from Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),

                  if (_selectedVideoFile != null) ...[
                    const SizedBox(height: 32),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Video Ready!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Size: ${(_selectedVideoFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
