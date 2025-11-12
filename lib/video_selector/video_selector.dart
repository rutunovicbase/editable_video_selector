// Video Selector Package
// A clean, SOLID-principles-based video selection library
//
// Simple Usage (Recommended):
// ```dart
// import 'package:editable_video_picker/video_selector/video_selector.dart';
//
// // Pick video from camera with editing
// final File? video = await VideoPicker.pickVideo(
//   context: context,
//   source: VideoSource.camera,
//   config: VideoPickerConfig.social(), // or .defaultConfig() or .quick()
// );
//
// if (video != null) {
//   // Use the processed video file
//   print('Video path: ${video.path}');
// }
//
// // Pick from gallery
// final File? galleryVideo = await VideoPicker.pickVideo(
//   context: context,
//   source: VideoSource.gallery,
// );
// ```
//
// Advanced Usage (Granular Control):
// ```dart
// final service = VideoSelectionService();
//
// // Select from camera
// final video = await service.selectVideo(
//   context: context,
//   source: VideoSelectionSource.camera,
// );
//
// // Select from gallery
// final video = await service.selectVideo(
//   context: context,
//   source: VideoSelectionSource.gallery,
// );
//
// // Trim video with custom settings
// final trimmerService = VideoTrimmerService(context: context);
// final trimData = await trimmerService.showTrimmerUI(
//   video,
//   maxDuration: Duration(seconds: 30),
//   minDuration: Duration(seconds: 3),
//   enableHandleDrag: true,
//   enableMiddleDrag: true,
// );
// final processedVideo = await trimmerService.trimVideo(video, trimData!);
// ```

library video_selector;

// ============================================================================
// MAIN PACKAGE API (Recommended for most use cases)
// ============================================================================
export 'video_picker.dart'
    show VideoPicker, VideoPickerConfig, VideoSource, VideoInfo;

// Camera Configuration
export 'screens/camera_recorder_screen.dart' show CameraRecorderConfig;

// Editor Configuration
export 'models/editor_config.dart' show EditorConfig;

// ============================================================================
// ADVANCED/GRANULAR APIs (For custom implementations)
// ============================================================================

// Services
export 'services/video_selection_service.dart';
export 'services/video_trimmer_service.dart';
export 'services/permission_service.dart';

// Models
export 'models/video_file.dart';
export 'models/video_selection_source.dart';
export 'models/trim_data.dart';

// Interfaces (for advanced usage and testing)
export 'interfaces/i_video_selection_strategy.dart';
export 'interfaces/i_video_trimmer.dart';
export 'interfaces/i_permission_handler.dart';

export 'models/video_picker_result.dart';
export 'models/trim_data.dart';
