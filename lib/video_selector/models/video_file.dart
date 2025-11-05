/// Model representing a video file with its metadata
class VideoFile {
  final String path;
  final Duration? duration;
  final String? thumbnailPath;
  final DateTime createdAt;

  const VideoFile({
    required this.path,
    this.duration,
    this.thumbnailPath,
    required this.createdAt,
  });

  VideoFile copyWith({
    String? path,
    Duration? duration,
    String? thumbnailPath,
    DateTime? createdAt,
  }) {
    return VideoFile(
      path: path ?? this.path,
      duration: duration ?? this.duration,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
