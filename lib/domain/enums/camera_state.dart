enum CameraState {
  idle,
  initializing,
  ready,
  error;

  bool get isReady => this == CameraState.ready;
  bool get isError => this == CameraState.error;
}
