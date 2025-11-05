/// A professional video selection package for Flutter with camera recording,
/// gallery picking, and video trimming capabilities.
///
/// This package provides a clean API for selecting and processing videos in Flutter apps.
library video_selector;

// Main API
export 'video_selector/video_picker.dart';
export 'video_selector/video_selector.dart' hide VideoSelectionService;

// Models
export 'video_selector/models/video_selection_source.dart';
export 'video_selector/models/editor_config.dart';
export 'video_selector/models/trim_data.dart';

// Services (for advanced usage)
export 'video_selector/services/permission_service.dart';
export 'video_selector/services/video_trimmer_service.dart';
