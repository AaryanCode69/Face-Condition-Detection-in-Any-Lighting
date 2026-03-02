/// 1-second sliding-window FPS tracker.
///
/// Skeleton in Phase 1; fully wired in Phase 6.
class FrameRateMonitor {
  final List<int> _timestamps = [];

  static const int _windowSizeMs = 1000;

  void recordFrame() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _timestamps
      ..add(now)
      ..removeWhere((t) => now - t > _windowSizeMs);
  }

  double get fps => _timestamps.length.toDouble();

  void reset() => _timestamps.clear();
}
