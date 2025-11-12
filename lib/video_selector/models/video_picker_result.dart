import 'dart:io';
import 'trim_data.dart';

/// Result from video picker containing both file and trim data
class VideoPickerResult {
  final File videoFile;
  final TrimData? trimData;  // Null if no editing was done

  const VideoPickerResult({
    required this.videoFile,
    this.trimData,
  });
}