/// Configuration for video editor behavior and constraints
class EditorConfig {
  /// Maximum allowed duration for the video
  final Duration maxDuration;

  /// Minimum required duration for the video
  final Duration minDuration;

  /// Enable dragging handles at the edges to adjust start/end
  final bool enableHandleDrag;

  /// Enable dragging from the middle section to move the entire selection
  final bool enableMiddleDrag;

  const EditorConfig({
    this.maxDuration = const Duration(seconds: 30),
    this.minDuration = const Duration(seconds: 1),
    this.enableHandleDrag = true,
    this.enableMiddleDrag = true,
  });

  /// Default balanced configuration
  factory EditorConfig.defaultConfig() => const EditorConfig();

  /// Configuration for social media (longer videos, all controls)
  factory EditorConfig.social() => const EditorConfig(
    maxDuration: Duration(seconds: 60),
    minDuration: Duration(seconds: 3),
    enableHandleDrag: true,
    enableMiddleDrag: true,
  );

  /// Quick edit configuration (simple, middle drag only)
  factory EditorConfig.quick() => const EditorConfig(
    maxDuration: Duration(seconds: 30),
    minDuration: Duration(seconds: 1),
    enableHandleDrag: false,
    enableMiddleDrag: true,
  );

  /// Precise editing (full control, strict limits)
  factory EditorConfig.precise({
    Duration? maxDuration,
    Duration? minDuration,
  }) => EditorConfig(
    maxDuration: maxDuration ?? const Duration(seconds: 15),
    minDuration: minDuration ?? const Duration(seconds: 3),
    enableHandleDrag: true,
    enableMiddleDrag: true,
  );

  /// Simple view-only (no drag controls, just preview)
  factory EditorConfig.viewOnly() =>
      const EditorConfig(enableHandleDrag: false, enableMiddleDrag: false);

  /// Copy with method for easy modifications
  EditorConfig copyWith({
    Duration? maxDuration,
    Duration? minDuration,
    bool? enableHandleDrag,
    bool? enableMiddleDrag,
  }) {
    return EditorConfig(
      maxDuration: maxDuration ?? this.maxDuration,
      minDuration: minDuration ?? this.minDuration,
      enableHandleDrag: enableHandleDrag ?? this.enableHandleDrag,
      enableMiddleDrag: enableMiddleDrag ?? this.enableMiddleDrag,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EditorConfig &&
        other.maxDuration == maxDuration &&
        other.minDuration == minDuration &&
        other.enableHandleDrag == enableHandleDrag &&
        other.enableMiddleDrag == enableMiddleDrag;
  }

  @override
  int get hashCode {
    return maxDuration.hashCode ^
        minDuration.hashCode ^
        enableHandleDrag.hashCode ^
        enableMiddleDrag.hashCode;
  }
}
