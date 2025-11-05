import 'package:flutter/material.dart';
import '../interfaces/i_video_selection_strategy.dart';
import '../interfaces/i_permission_handler.dart';
import '../models/video_file.dart';
import '../models/video_selection_source.dart';
import '../strategies/camera_video_selection_strategy.dart';
import '../strategies/gallery_video_selection_strategy.dart';
import '../services/permission_service.dart';

/// Main video selection service (Facade Pattern + Dependency Injection)
class VideoSelectionService {
  final IPermissionHandler _permissionHandler;

  VideoSelectionService({IPermissionHandler? permissionHandler})
    : _permissionHandler = permissionHandler ?? PermissionService();

  /// Select video based on source (Strategy Pattern)
  Future<VideoFile?> selectVideo({
    required BuildContext context,
    required VideoSelectionSource source,
  }) async {
    final IVideoSelectionStrategy strategy = _getStrategy(context, source);
    return await strategy.selectVideo();
  }

  /// Get appropriate strategy based on source
  IVideoSelectionStrategy _getStrategy(
    BuildContext context,
    VideoSelectionSource source,
  ) {
    switch (source) {
      case VideoSelectionSource.camera:
        return CameraVideoSelectionStrategy(
          context: context,
          permissionHandler: _permissionHandler,
        );
      case VideoSelectionSource.gallery:
        return GalleryVideoSelectionStrategy(
          permissionHandler: _permissionHandler,
        );
    }
  }
}
