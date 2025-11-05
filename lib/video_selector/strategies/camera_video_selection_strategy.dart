import 'package:flutter/material.dart';
import '../interfaces/i_video_selection_strategy.dart';
import '../models/video_file.dart';
import '../interfaces/i_permission_handler.dart';
import '../screens/camera_recorder_screen.dart';

/// Strategy for recording video from camera (Single Responsibility)
class CameraVideoSelectionStrategy implements IVideoSelectionStrategy {
  final BuildContext context;
  final IPermissionHandler _permissionHandler;

  CameraVideoSelectionStrategy({
    required this.context,
    required IPermissionHandler permissionHandler,
  }) : _permissionHandler = permissionHandler;

  @override
  Future<VideoFile?> selectVideo() async {
    // Request camera and microphone permissions
    final cameraGranted = await _permissionHandler.requestCameraPermission();
    final micGranted = await _permissionHandler.requestMicrophonePermission();

    if (!cameraGranted || !micGranted) {
      return null;
    }

    try {
      // Navigate to camera recorder screen
      if (!context.mounted) return null;

      final result = await Navigator.of(context).push<VideoFile>(
        MaterialPageRoute(builder: (context) => const CameraRecorderScreen()),
      );

      return result;
    } catch (e) {
      // Log error in production
      return null;
    }
  }
}
