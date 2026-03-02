enum DetectionState {
  idle,
  detecting,

  /// e.g. app backgrounded.
  paused,
  error;

  bool get isActive => this == DetectionState.detecting;
  bool get canResume =>
      this == DetectionState.paused || this == DetectionState.idle;
}
