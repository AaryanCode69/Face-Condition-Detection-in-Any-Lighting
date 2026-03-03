class InferenceTimer {
  int? _startTime;
  int _lastFaceDetectionMs = 0;
  int _lastEmotionMs = 0;
  int _lastTotalMs = 0;

  void start() {
    _startTime = DateTime.now().millisecondsSinceEpoch;
  }

  void recordFaceDetection() {
    if (_startTime == null) return;
    _lastFaceDetectionMs =
        DateTime.now().millisecondsSinceEpoch - _startTime!;
  }

  void recordEmotionAnalysis() {
    if (_startTime == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastEmotionMs = now - _startTime! - _lastFaceDetectionMs;
  }

  void stop() {
    if (_startTime == null) return;
    _lastTotalMs = DateTime.now().millisecondsSinceEpoch - _startTime!;
    _startTime = null;
  }

  int get faceDetectionMs => _lastFaceDetectionMs;
  int get emotionMs => _lastEmotionMs;
  int get totalMs => _lastTotalMs;

  void reset() {
    _startTime = null;
    _lastFaceDetectionMs = 0;
    _lastEmotionMs = 0;
    _lastTotalMs = 0;
  }
}
