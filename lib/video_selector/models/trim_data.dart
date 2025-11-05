/// Model representing video trim data
class TrimData {
  final Duration startTime;
  final Duration endTime;
  final Duration maxDuration;

  const TrimData({
    required this.startTime,
    required this.endTime,
    this.maxDuration = const Duration(seconds: 30),
  });

  Duration get trimmedDuration => endTime - startTime;

  bool get isValid =>
      startTime >= Duration.zero &&
      endTime > startTime &&
      trimmedDuration <= maxDuration;

  TrimData copyWith({
    Duration? startTime,
    Duration? endTime,
    Duration? maxDuration,
  }) {
    return TrimData(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxDuration: maxDuration ?? this.maxDuration,
    );
  }
}
