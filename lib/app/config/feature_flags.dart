class FeatureFlags {
  const FeatureFlags({
    this.enableEmotionAnalysis = true,
    this.enableLightingAnalysis = true,
    this.enableLightingAdaptation = true,
    this.enableFpsOverlay = false,
    this.enableDebugLogging = true,
    this.enableIsolateInference = false,
  });

  final bool enableEmotionAnalysis;
  final bool enableLightingAnalysis;
  final bool enableLightingAdaptation;
  final bool enableFpsOverlay;
  final bool enableDebugLogging;

  final bool enableIsolateInference;

  FeatureFlags copyWith({
    bool? enableEmotionAnalysis,
    bool? enableLightingAnalysis,
    bool? enableLightingAdaptation,
    bool? enableFpsOverlay,
    bool? enableDebugLogging,
    bool? enableIsolateInference,
  }) {
    return FeatureFlags(
      enableEmotionAnalysis:
          enableEmotionAnalysis ?? this.enableEmotionAnalysis,
      enableLightingAnalysis:
          enableLightingAnalysis ?? this.enableLightingAnalysis,
      enableLightingAdaptation:
          enableLightingAdaptation ?? this.enableLightingAdaptation,
      enableFpsOverlay: enableFpsOverlay ?? this.enableFpsOverlay,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
      enableIsolateInference:
          enableIsolateInference ?? this.enableIsolateInference,
    );
  }
}
