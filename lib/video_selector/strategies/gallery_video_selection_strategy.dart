import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../interfaces/i_video_selection_strategy.dart';
import '../models/video_file.dart';
import '../interfaces/i_permission_handler.dart';

/// Strategy for selecting video from gallery (Single Responsibility)
class GalleryVideoSelectionStrategy implements IVideoSelectionStrategy {
  final ImagePicker _picker;
  final IPermissionHandler _permissionHandler;

  GalleryVideoSelectionStrategy({
    ImagePicker? picker,
    required IPermissionHandler permissionHandler,
  }) : _picker = picker ?? ImagePicker(),
       _permissionHandler = permissionHandler;

  @override
  Future<VideoFile?> selectVideo() async {
    try {
      // Request storage permission

      debugPrint('📱 Gallery: Opening picker...');

      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10), // Allow up to 10 min videos
      );

      if (video == null) {
        debugPrint('ℹ️ Gallery: User cancelled video selection');
        return null;
      }

      debugPrint('✅ Gallery: Video selected: ${video.path}');

      // Verify the file exists
      final videoFile = VideoFile(path: video.path, createdAt: DateTime.now());
      debugPrint('📹 Gallery: Video file created: ${videoFile.path}');

      return videoFile;
    } catch (e, stackTrace) {
      debugPrint('❌ Gallery picker error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}
