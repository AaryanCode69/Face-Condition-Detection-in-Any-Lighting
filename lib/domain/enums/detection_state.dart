enum DetectionState {
  idle,
  detecting,
  paused,
  error;

  bool get isActive => this == DetectionState.detecting;
  bool get canResume =>
      this == DetectionState.paused || this == DetectionState.idle;
}
