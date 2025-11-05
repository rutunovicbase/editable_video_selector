import 'dart:io';
import 'package:flutter/material.dart';
import 'models/video_file.dart';
import 'models/video_selection_source.dart';
import 'models/editor_config.dart';
import 'services/video_selection_service.dart';
import 'services/video_trimmer_service.dart';
import 'screens/camera_recorder_screen.dart';

/// Configuration for the entire video picker flow
class VideoPickerConfig {
  // Camera configuration
  final CameraRecorderConfig? cameraConfig;

  // Editor configuration (controls min/max duration and drag behavior)
  final EditorConfig editorConfig;

  // Flow configuration
  final bool autoTrim;
  final bool requireEditing;

  const VideoPickerConfig({
    this.cameraConfig,
    this.editorConfig = const EditorConfig(),
    this.autoTrim = true,
    this.requireEditing = true,
  });

  /// Backward compatibility: Create config with individual editor params
  factory VideoPickerConfig.withEditorParams({
    CameraRecorderConfig? cameraConfig,
    Duration maxDuration = const Duration(seconds: 30),
    Duration minDuration = const Duration(seconds: 1),
    bool enableHandleDrag = true,
    bool enableMiddleDrag = true,
    bool autoTrim = true,
    bool requireEditing = true,
  }) => VideoPickerConfig(
    cameraConfig: cameraConfig,
    editorConfig: EditorConfig(
      maxDuration: maxDuration,
      minDuration: minDuration,
      enableHandleDrag: enableHandleDrag,
      enableMiddleDrag: enableMiddleDrag,
    ),
    autoTrim: autoTrim,
    requireEditing: requireEditing,
  );

  factory VideoPickerConfig.defaultConfig() => const VideoPickerConfig();

  factory VideoPickerConfig.social() => VideoPickerConfig(
    cameraConfig: CameraRecorderConfig.professional(),
    editorConfig: EditorConfig.social(),
    autoTrim: true,
    requireEditing: true,
  );

  factory VideoPickerConfig.quick() => VideoPickerConfig(
    cameraConfig: CameraRecorderConfig.simple(),
    editorConfig: EditorConfig.quick(),
    autoTrim: false,
    requireEditing: false,
  );
}

/// Main Video Picker Package API
///
/// Use this class to pick and process videos in your Flutter app.
/// Returns a processed video File ready to use.
///
/// Example:
/// ```dart
/// final File? videoFile = await VideoPicker.pickVideo(
///   context: context,
///   source: VideoSource.camera,
///   config: VideoPickerConfig.social(),
/// );
///
/// if (videoFile != null) {
///   // Use the processed video file
/// }
/// ```
class VideoPicker {
  VideoPicker._(); // Private constructor to prevent instantiation

  /// Pick a video from camera or gallery with optional editing
  ///
  /// Returns a [File] containing the processed video, or null if cancelled.
  ///
  /// Parameters:
  /// - [context]: BuildContext for navigation
  /// - [source]: VideoSource.camera or VideoSource.gallery
  /// - [config]: Optional configuration for camera, editor, and flow
  static Future<File?> pickVideo({
    required BuildContext context,
    required VideoSource source,
    VideoPickerConfig config = const VideoPickerConfig(),
  }) async {
    try {
      final videoSelectionService = VideoSelectionService();
      final videoTrimmerService = VideoTrimmerService(context: context);

      // Step 1: Select/Record video
      VideoFile? selectedVideo;

      if (source == VideoSource.camera) {
        debugPrint('📹 VideoPicker: Opening camera...');
        selectedVideo = await _pickFromCamera(context, config);
      } else {
        debugPrint('📱 VideoPicker: Opening gallery...');
        selectedVideo = await videoSelectionService.selectVideo(
          context: context,
          source: VideoSelectionSource.gallery,
        );
      }

      if (selectedVideo == null) {
        debugPrint('ℹ️ VideoPicker: No video selected');
        return null;
      }

      if (!context.mounted) {
        debugPrint('⚠️ VideoPicker: Context not mounted');
        return null;
      }

      debugPrint('✅ VideoPicker: Video selected: ${selectedVideo.path}');

      // Step 2: Edit video (if required)
      if (config.requireEditing) {
        debugPrint('✂️ VideoPicker: Opening editor...');
        final trimData = await videoTrimmerService.showTrimmerUI(
          selectedVideo,
          editorConfig: config.editorConfig,
        );

        if (trimData == null || !context.mounted) {
          debugPrint('ℹ️ VideoPicker: Editing cancelled');
          return null; // User cancelled editing
        }

        debugPrint(
          '✅ VideoPicker: Trim data received: ${trimData.startTime} - ${trimData.endTime}',
        );

        // Step 3: Process/trim video (if needed)
        if (config.autoTrim) {
          debugPrint('🔧 VideoPicker: Processing video...');
          final processedVideo = await videoTrimmerService.trimVideo(
            selectedVideo,
            trimData,
          );

          if (processedVideo != null) {
            debugPrint(
              '✅ VideoPicker: Video processed: ${processedVideo.path}',
            );
            return File(processedVideo.path);
          }
          debugPrint('❌ VideoPicker: Video processing failed');
          return null;
        } else {
          // Return original video file
          debugPrint('✅ VideoPicker: Returning original video (no trim)');
          return File(selectedVideo.path);
        }
      } else {
        // No editing required, return original
        debugPrint('✅ VideoPicker: Returning original video (no editing)');
        return File(selectedVideo.path);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ VideoPicker error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Pick a video from camera
  static Future<VideoFile?> _pickFromCamera(
    BuildContext context,
    VideoPickerConfig config,
  ) async {
    final cameraConfig =
        config.cameraConfig ?? CameraRecorderConfig.defaultConfig();

    if (!context.mounted) return null;

    final video = await Navigator.push<VideoFile>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraRecorderScreen(config: cameraConfig),
      ),
    );

    return video;
  }

  /// Pick multiple videos (future feature)
  static Future<List<File>?> pickMultipleVideos({
    required BuildContext context,
    VideoPickerConfig config = const VideoPickerConfig(),
  }) async {
    // TODO: Implement multiple video selection
    throw UnimplementedError('Multiple video selection coming soon');
  }

  /// Get video info without picking
  static Future<VideoInfo?> getVideoInfo(File videoFile) async {
    // TODO: Implement video info extraction
    throw UnimplementedError('Video info extraction coming soon');
  }
}

/// Video source enum for better API
enum VideoSource { camera, gallery }

/// Video information class (future feature)
class VideoInfo {
  final Duration duration;
  final int width;
  final int height;
  final int fileSize;
  final String path;

  const VideoInfo({
    required this.duration,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.path,
  });
}
