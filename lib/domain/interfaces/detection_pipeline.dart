import 'package:face_mood_light_detector/domain/entities/detection_frame.dart';

class PipelineConfig {
  const PipelineConfig({
    this.faceConfidenceThreshold = 0.5,
    this.targetFps = 10,
    this.enableEmotionAnalysis = true,
    this.enableLightingAnalysis = true,
    this.exposureOffset = 0,
    this.contrastBoost = false,
    this.gammaCorrection = false,
  });

  final double faceConfidenceThreshold;
  final int targetFps;
  final bool enableEmotionAnalysis;
  final bool enableLightingAnalysis;

  /// EV stops.
  final double exposureOffset;

  /// For dim lighting preprocessing.
  final bool contrastBoost;

  /// For bright lighting preprocessing.
  final bool gammaCorrection;

  PipelineConfig copyWith({
    double? faceConfidenceThreshold,
    int? targetFps,
    bool? enableEmotionAnalysis,
    bool? enableLightingAnalysis,
    double? exposureOffset,
    bool? contrastBoost,
    bool? gammaCorrection,
  }) {
    return PipelineConfig(
      faceConfidenceThreshold:
          faceConfidenceThreshold ?? this.faceConfidenceThreshold,
      targetFps: targetFps ?? this.targetFps,
      enableEmotionAnalysis:
          enableEmotionAnalysis ?? this.enableEmotionAnalysis,
      enableLightingAnalysis:
          enableLightingAnalysis ?? this.enableLightingAnalysis,
      exposureOffset: exposureOffset ?? this.exposureOffset,
      contrastBoost: contrastBoost ?? this.contrastBoost,
      gammaCorrection: gammaCorrection ?? this.gammaCorrection,
    );
  }
}

class PipelineMetrics {
  const PipelineMetrics({
    this.detectionFps = 0,
    this.faceDetectionLatencyMs = 0,
    this.emotionLatencyMs = 0,
    this.totalLatencyMs = 0,
    this.frameDropRate = 0,
  });

  final double detectionFps;
  final int faceDetectionLatencyMs;
  final int emotionLatencyMs;
  final int totalLatencyMs;

  /// 0.0–1.0.
  final double frameDropRate;
}

/// Composes face detection + emotion + lighting into an ordered pipeline.
abstract class DetectionPipeline {
  Stream<DetectionFrame> get resultStream;
  Future<void> start();
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  void updateConfig(PipelineConfig config);
  PipelineMetrics get metrics;
}
