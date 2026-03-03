/// Controls frame processing rate with a drop-newest policy.
class FrameThrottleService {
  FrameThrottleService({int targetFps = 10}) : _targetFps = targetFps;

  int _targetFps;
  bool _isBusy = false;
  int _lastProcessedTimestampMs = 0;
  int _droppedFrames = 0;
  int _processedFrames = 0;

  int get targetFps => _targetFps;

  set targetFps(int value) => _targetFps = value.clamp(1, 30);

  bool get isBusy => _isBusy;
  int get droppedFrames => _droppedFrames;
  int get processedFrames => _processedFrames;

  /// 0.0–1.0 fraction of frames dropped.
  double get dropRate {
    final total = _processedFrames + _droppedFrames;
    if (total == 0) return 0;
    return _droppedFrames / total;
  }

  /// Returns `true` if the frame should be processed;
  /// `false` if it should be dropped (pipeline busy or rate-limited).
  bool shouldProcessFrame() {
    if (_isBusy) {
      _droppedFrames++;
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final minIntervalMs = (1000 / _targetFps).round();

    if (now - _lastProcessedTimestampMs < minIntervalMs) {
      _droppedFrames++;
      return false;
    }

    _lastProcessedTimestampMs = now;
    _processedFrames++;
    return true;
  }

  void markBusy() => _isBusy = true;
  void markIdle() => _isBusy = false;

  void reset() {
    _droppedFrames = 0;
    _processedFrames = 0;
    _lastProcessedTimestampMs = 0;
    _isBusy = false;
  }
}
