/// All detection thresholds, model paths, and tuning knobs.
class AppConfig {
  const AppConfig({
    this.defaultFaceConfidenceThreshold = 0.5,
    this.dimLightConfidenceThreshold = 0.3,
    this.brightLightConfidenceThreshold = 0.7,
    this.emotionModelPath = 'assets/models/emotion_classifier.tflite',
    this.emotionSmoothingWindowSize = 5,
    this.lightingSmoothingWindowSize = 10,
    this.lightingMajorityVoteThreshold = 7,
    this.defaultTargetFps = 10,
    this.meanBrightnessDimThreshold = 50.0,
    this.meanBrightnessBrightThreshold = 200.0,
    this.overexposedPercentThreshold = 0.30,
    this.underexposedPercentThreshold = 0.40,
    this.circuitBreakerFailureThreshold = 5,
    this.circuitBreakerResetDuration = const Duration(seconds: 2),
  });

  final double defaultFaceConfidenceThreshold;
  final double dimLightConfidenceThreshold;
  final double brightLightConfidenceThreshold;

  final String emotionModelPath;

  /// Number of frames in the emotion smoothing sliding window.
  final int emotionSmoothingWindowSize;

  /// Number of frames in the lighting smoothing sliding window.
  final int lightingSmoothingWindowSize;

  /// Out of [lightingSmoothingWindowSize], how many must agree.
  final int lightingMajorityVoteThreshold;

  /// Y-channel mean (0–255) below which lighting is classified dim.
  final double meanBrightnessDimThreshold;

  /// Y-channel mean (0–255) above which lighting is classified bright.
  final double meanBrightnessBrightThreshold;

  /// Fraction of pixels > 240 to trigger overexposure classification.
  final double overexposedPercentThreshold;

  /// Fraction of pixels < 20 to trigger underexposure classification.
  final double underexposedPercentThreshold;

  final int defaultTargetFps;

  /// Consecutive failures before the circuit breaker trips.
  final int circuitBreakerFailureThreshold;
  final Duration circuitBreakerResetDuration;
}
