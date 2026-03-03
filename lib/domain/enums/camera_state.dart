/// Camera lifecycle state.
enum CameraState {
  /// Camera not yet initialized.
  idle,

  /// Camera is being initialized or switching.
  initializing,

  /// Camera is ready and streaming.
  ready,

  /// Camera encountered an error.
  error;

  bool get isReady => this == CameraState.ready;
  bool get isError => this == CameraState.error;
}
