import 'dart:io';
import 'package:editable_video_picker/video_selector/services/permission_service.dart';
import 'package:flutter/material.dart';
import 'models/video_file.dart';
import 'models/video_selection_source.dart';
import 'models/editor_config.dart';
import 'models/video_picker_result.dart'; // ✅ Add this import
import 'models/trim_data.dart'; // ✅ Add this import
import 'services/video_selection_service.dart';
import 'services/video_trimmer_service.dart';
import 'screens/camera_recorder_screen.dart';

/// Configuration for the entire video picker flow
class VideoPickerConfig {
  final CameraRecorderConfig? cameraConfig;
  final EditorConfig editorConfig;
  final bool autoTrim;
  final bool requireEditing;

  const VideoPickerConfig({
    this.cameraConfig,
    this.editorConfig = const EditorConfig(),
    this.autoTrim = true,
    this.requireEditing = true,
  });

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

class VideoPicker {
  VideoPicker._();

  static final _permissionService = PermissionService();

  static Future<VideoPickerResult?> pickVideoWithTrimData({
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
        selectedVideo = await videoSelectionService.selectVideo(context: context, source: VideoSelectionSource.gallery);
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

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA561CA)),
              ),
            ),
          ),
        );
      }

      // Step 2: Edit video (if required)
      TrimData? trimData;

      if (config.requireEditing) {
        debugPrint('✂️ VideoPicker: Opening editor...');
        trimData = await videoTrimmerService.showTrimmerUI(selectedVideo, editorConfig: config.editorConfig);

        if (context.mounted) {
          Navigator.of(context).pop();
        }

        if (trimData == null || !context.mounted) {
          debugPrint('ℹ️ VideoPicker: Editing cancelled');
          return null;
        }

        debugPrint('✅ VideoPicker: Trim data received: ${trimData.startTime} - ${trimData.endTime}');
      } else {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      }

      // Return both video file and trim data
      debugPrint('✅ VideoPicker: Returning video with trim data');
      return VideoPickerResult(videoFile: File(selectedVideo.path), trimData: trimData);
    } catch (e, stackTrace) {
      debugPrint('❌ VideoPicker error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      return null;
    }
  }

  /// OLD: Keep for backward compatibility
  static Future<File?> pickVideo({
    required BuildContext context,
    required VideoSource source,
    VideoPickerConfig config = const VideoPickerConfig(),
  }) async {
    final result = await pickVideoWithTrimData(context: context, source: source, config: config);
    return result?.videoFile;
  }

  static Future<VideoFile?> _pickFromCamera(BuildContext context, VideoPickerConfig config) async {
    final cameraConfig = config.cameraConfig ?? CameraRecorderConfig.defaultConfig();

    if (!context.mounted) return null;

    final video = await Navigator.push<VideoFile>(
      context,
      MaterialPageRoute(builder: (context) => CameraRecorderScreen(config: cameraConfig)),
    );

    return video;
  }
}

enum VideoSource { camera, gallery }

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
