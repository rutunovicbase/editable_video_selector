import '../models/video_file.dart';

/// Interface for video selection strategy (Strategy Pattern + Interface Segregation)
abstract class IVideoSelectionStrategy {
  Future<VideoFile?> selectVideo();
}
