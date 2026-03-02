/// Phase 1 stub — implemented in Phase 3.
/// Drops frames when the ML pipeline can't keep up, maintaining
/// target FPS without back-pressure.
class FrameThrottleService {
  double targetFps = 15;

  bool shouldProcessFrame() {
    // TODO(phase3): Timestamp-based throttling logic.
    return true;
  }

  void recordProcessed() {}
}
