import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../interfaces/i_video_trimmer.dart';
import '../models/trim_data.dart';
import '../models/video_file.dart';
import '../models/editor_config.dart';
import '../screens/video_editor_screen.dart';

/// Service for trimming videos
class VideoTrimmerService implements IVideoTrimmer {
  final BuildContext context;

  VideoTrimmerService({required this.context});

  /// Show trimmer UI and get trim data from user
  Future<TrimData?> showTrimmerUI(
    VideoFile videoFile, {
    EditorConfig? editorConfig,
    // Backward compatibility params (deprecated)
    Duration? maxDuration,
    Duration? minDuration,
    bool? enableHandleDrag,
    bool? enableMiddleDrag,
  }) async {
    // Use editorConfig if provided, otherwise create from individual params
    final config =
        editorConfig ??
        EditorConfig(
          maxDuration: maxDuration ?? const Duration(seconds: 30),
          minDuration: minDuration ?? const Duration(seconds: 1),
          enableHandleDrag: enableHandleDrag ?? true,
          enableMiddleDrag: enableMiddleDrag ?? true,
        );

    final result = await Navigator.of(context).push<TrimData>(
      MaterialPageRoute(
        builder: (context) => VideoEditorScreen(
          videoFile: videoFile,
          maxDuration: config.maxDuration,
          minDuration: config.minDuration,
          enableHandleDrag: config.enableHandleDrag,
          enableMiddleDrag: config.enableMiddleDrag,
        ),
      ),
    );

    return result;
  }

  @override
  Future<VideoFile?> trimVideo(VideoFile videoFile, TrimData trimData) async {
    if (!trimData.isValid) {
      return null;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final info = await VideoCompress.compressVideo(
        videoFile.path,
        startTime: trimData.startTime.inMilliseconds,
        duration: trimData.trimmedDuration.inMilliseconds,
        deleteOrigin: false,
      );

      if (info == null || info.file == null) {
        return null;
      }

      // Copy to permanent location
      final appDir = await getApplicationDocumentsDirectory();
      final finalPath = path.join(appDir.path, 'trimmed_video_$timestamp.mp4');

      await info.file!.copy(finalPath);

      return VideoFile(
        path: finalPath,
        duration: trimData.trimmedDuration,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      // Log error in production
      return null;
    }
  }
}
