import '../models/trim_data.dart';
import '../models/video_file.dart';

/// Interface for video trimming functionality
abstract class IVideoTrimmer {
  Future<VideoFile?> trimVideo(VideoFile videoFile, TrimData trimData);
}
