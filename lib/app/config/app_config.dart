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
  final int emotionSmoothingWindowSize;
  final int lightingSmoothingWindowSize;

  /// Out of [lightingSmoothingWindowSize], how many must agree.
  final int lightingMajorityVoteThreshold;
  final double meanBrightnessDimThreshold;
  final double meanBrightnessBrightThreshold;
  final double overexposedPercentThreshold;
  final double underexposedPercentThreshold;

  final int defaultTargetFps;
  /// Consecutive failures before the circuit breaker trips.
  final int circuitBreakerFailureThreshold;
  final Duration circuitBreakerResetDuration;
}
