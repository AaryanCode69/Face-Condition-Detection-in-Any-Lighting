import 'dart:math' as math;
import 'dart:ui';

import 'package:face_mood_light_detector/data/models/raw_emotion_data.dart';
import 'package:face_mood_light_detector/data/models/raw_face_data.dart';
import 'package:face_mood_light_detector/domain/entities/emotion_result.dart';
import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:face_mood_light_detector/domain/enums/emotion_type.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'
    as mlkit;

/// Converts raw ML Kit / TFLite output to domain entities.
class ResultMapper {
  const ResultMapper._();

  static FaceDetectionResult fromMlKitFace(mlkit.Face face) {
    return FaceDetectionResult(
      boundingBox: Rect.fromLTRB(
        face.boundingBox.left,
        face.boundingBox.top,
        face.boundingBox.right,
        face.boundingBox.bottom,
      ),
      confidence: _computeConfidence(face),
      landmarks: _mapLandmarks(face),
      trackingId: face.trackingId,
      smilingProbability: face.smilingProbability,
      leftEyeOpenProbability: face.leftEyeOpenProbability,
      rightEyeOpenProbability: face.rightEyeOpenProbability,
    );
  }

  static RawFaceData toRawFaceData(mlkit.Face face) {
    final landmarks = <String, Offset>{};
    for (final entry in _landmarkMapping.entries) {
      final lm = face.landmarks[entry.key];
      if (lm != null) {
        landmarks[entry.value] =
            Offset(lm.position.x.toDouble(), lm.position.y.toDouble());
      }
    }

    return RawFaceData(
      boundingBox: Rect.fromLTRB(
        face.boundingBox.left,
        face.boundingBox.top,
        face.boundingBox.right,
        face.boundingBox.bottom,
      ),
      landmarks: landmarks,
      trackingId: face.trackingId,
      headEulerAngleX: face.headEulerAngleX,
      headEulerAngleY: face.headEulerAngleY,
      headEulerAngleZ: face.headEulerAngleZ,
      smilingProbability: face.smilingProbability,
      leftEyeOpenProbability: face.leftEyeOpenProbability,
      rightEyeOpenProbability: face.rightEyeOpenProbability,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// ML Kit doesn't expose a single detection confidence score;
  /// we default to 0.9/0.95 since ML Kit already filters internally.
  static double _computeConfidence(mlkit.Face face) {
    final scores = <double>[
      if (face.smilingProbability != null) face.smilingProbability!,
      if (face.leftEyeOpenProbability != null) face.leftEyeOpenProbability!,
      if (face.rightEyeOpenProbability != null) face.rightEyeOpenProbability!,
    ];

    if (scores.isEmpty) return 0.9;
    return 0.95;
  }

  static List<Landmark> _mapLandmarks(mlkit.Face face) {
    final result = <Landmark>[];

    for (final entry in _landmarkMapping.entries) {
      final lm = face.landmarks[entry.key];
      if (lm != null) {
        final type = _landmarkTypeFromString(entry.value);
        if (type != null) {
          result.add(
            Landmark(
              type: type,
              position: Offset(
                lm.position.x.toDouble(),
                lm.position.y.toDouble(),
              ),
            ),
          );
        }
      }
    }

    return result;
  }

  static const _landmarkMapping = <mlkit.FaceLandmarkType, String>{
    mlkit.FaceLandmarkType.leftEye: 'leftEye',
    mlkit.FaceLandmarkType.rightEye: 'rightEye',
    mlkit.FaceLandmarkType.noseBase: 'noseBase',
    mlkit.FaceLandmarkType.leftMouth: 'leftMouth',
    mlkit.FaceLandmarkType.rightMouth: 'rightMouth',
    mlkit.FaceLandmarkType.leftEar: 'leftEar',
    mlkit.FaceLandmarkType.rightEar: 'rightEar',
    mlkit.FaceLandmarkType.leftCheek: 'leftCheek',
    mlkit.FaceLandmarkType.rightCheek: 'rightCheek',
    mlkit.FaceLandmarkType.bottomMouth: 'bottomMouth',
  };

  static LandmarkType? _landmarkTypeFromString(String name) {
    switch (name) {
      case 'leftEye':
        return LandmarkType.leftEye;
      case 'rightEye':
        return LandmarkType.rightEye;
      case 'noseBase':
        return LandmarkType.noseBase;
      case 'leftMouth':
        return LandmarkType.leftMouth;
      case 'rightMouth':
        return LandmarkType.rightMouth;
      case 'leftEar':
        return LandmarkType.leftEar;
      case 'rightEar':
        return LandmarkType.rightEar;
      case 'leftCheek':
        return LandmarkType.leftCheek;
      case 'rightCheek':
        return LandmarkType.rightCheek;
      case 'bottomMouth':
        return LandmarkType.bottomMouth;
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Emotion mapping (TFLite raw output → EmotionResult)
  // ---------------------------------------------------------------------------

  /// 8-class model output order (FER-2013 + contempt):
  /// [angry, disgust, fear, happy, sad, surprise, neutral, contempt]
  ///
  /// We map these to our 5-class [EmotionType] enum:
  /// - angry + fear → stressed
  /// - disgust + surprise + contempt → neutral (low-signal classes)
  /// - happy → happy
  /// - sad → sad
  /// - neutral → neutral
  ///
  /// "tired" is inferred from ML Kit face data (eye open probability)
  /// in [fromRawEmotionWithFaceData].
  static const _ferToEmotionType = <int, EmotionType>{
    0: EmotionType.stressed, // angry
    1: EmotionType.neutral, // disgust → neutral
    2: EmotionType.stressed, // fear → stressed
    3: EmotionType.happy, // happy
    4: EmotionType.sad, // sad
    5: EmotionType.neutral, // surprise → neutral
    6: EmotionType.neutral, // neutral
    7: EmotionType.neutral, // contempt → neutral
  };

  /// Converts raw TFLite output to [EmotionResult].
  ///
  /// Auto-detects whether the model output is already softmaxed
  /// (probabilities) or raw logits. Uses MAX-based aggregation (not SUM)
  /// to prevent bias toward categories with multiple source classes.
  static EmotionResult fromRawEmotion(RawEmotionData raw) {
    if (raw.outputScores.isEmpty) return const EmotionResult.unknown();

    // Auto-detect: if values are already probabilities, skip softmax.
    final probabilities = _ensureProbabilities(raw.outputScores);

    // Aggregate into our 5-class system using MAX (not SUM).
    // Using SUM would bias "stressed" (angry + fear) over "happy" (1 source).
    final aggregated = <EmotionType, double>{};
    for (final type in EmotionType.values) {
      aggregated[type] = 0;
    }

    for (var i = 0; i < probabilities.length && i < 8; i++) {
      final mapped = _ferToEmotionType[i] ?? EmotionType.neutral;
      aggregated[mapped] = math.max(aggregated[mapped]!, probabilities[i]);
    }

    // Re-normalise so confidences sum to 1.0.
    final total =
        aggregated.values.fold<double>(0, (sum, v) => sum + v);
    if (total > 0) {
      for (final key in aggregated.keys) {
        aggregated[key] = aggregated[key]! / total;
      }
    }

    // Find dominant.
    var dominant = EmotionType.neutral;
    var maxConf = 0.0;
    for (final entry in aggregated.entries) {
      if (entry.value > maxConf) {
        maxConf = entry.value;
        dominant = entry.key;
      }
    }

    return EmotionResult(
      dominantEmotion: dominant,
      confidences: aggregated,
    );
  }

  /// Enhanced emotion mapping that also considers ML Kit face features
  /// (eye open probability) to detect "tired".
  static EmotionResult fromRawEmotionWithFaceData(
    RawEmotionData raw,
    RawFaceData? faceData,
  ) {
    final base = fromRawEmotion(raw);
    if (faceData == null || !base.isValid) return base;

    return adjustWithFaceFeatures(
      base,
      smilingProbability: faceData.smilingProbability,
      leftEyeOpenProbability: faceData.leftEyeOpenProbability,
      rightEyeOpenProbability: faceData.rightEyeOpenProbability,
    );
  }

  /// Post-hoc adjustment of an [EmotionResult] using ML Kit face features.
  ///
  /// ML Kit's `smilingProbability` and eye-open probability are reliable
  /// hardware-accelerated classifiers that supplement the TFLite model.
  /// This is called by the pipeline after emotion inference.
  static EmotionResult adjustWithFaceFeatures(
    EmotionResult base, {
    double? smilingProbability,
    double? leftEyeOpenProbability,
    double? rightEyeOpenProbability,
  }) {
    if (!base.isValid) return base;

    final confidences = Map<EmotionType, double>.from(base.confidences);

    // ----- Smile boost -----
    // ML Kit's smile detection is very reliable — use it as a strong
    // signal to correct the TFLite classifier.
    if (smilingProbability != null && smilingProbability > 0.5) {
      // Scale: at 0.5 smile → small boost; at 1.0 smile → large boost.
      final happyBoost = (smilingProbability - 0.3) * 0.9; // max ~0.63
      confidences[EmotionType.happy] =
          (confidences[EmotionType.happy] ?? 0) + happyBoost;

      // Smiling contradicts stress — dampen stressed proportionally.
      confidences[EmotionType.stressed] =
          (confidences[EmotionType.stressed] ?? 0) *
              (1.0 - smilingProbability * 0.6);
      confidences[EmotionType.sad] =
          (confidences[EmotionType.sad] ?? 0) *
              (1.0 - smilingProbability * 0.5);
    }

    // ----- Tiredness from eye openness -----
    if (leftEyeOpenProbability != null && rightEyeOpenProbability != null) {
      final avgEyeOpen =
          (leftEyeOpenProbability + rightEyeOpenProbability) / 2;
      // Eyes mostly closed or squinting → boost tired score.
      if (avgEyeOpen < 0.4) {
        final tiredBoost = (0.4 - avgEyeOpen) * 1.5; // max ~0.6
        confidences[EmotionType.tired] =
            (confidences[EmotionType.tired] ?? 0) + tiredBoost;
      }
    }

    // Re-normalise.
    final total =
        confidences.values.fold<double>(0, (sum, v) => sum + v);
    if (total > 0) {
      for (final key in confidences.keys) {
        confidences[key] = confidences[key]! / total;
      }
    }

    // Find new dominant.
    var dominant = EmotionType.neutral;
    var maxConf = 0.0;
    for (final entry in confidences.entries) {
      if (entry.value > maxConf) {
        maxConf = entry.value;
        dominant = entry.key;
      }
    }

    return EmotionResult(
      dominantEmotion: dominant,
      confidences: confidences,
    );
  }

  /// Returns probabilities. Applies softmax only if the values appear to
  /// be raw logits rather than already-softmaxed probabilities.
  ///
  /// Many TFLite models include softmax as the final layer, so applying
  /// softmax again would compress differences and distort results.
  static List<double> _ensureProbabilities(List<double> scores) {
    final allInUnitRange = scores.every((v) => v >= -0.001 && v <= 1.001);
    final sum = scores.fold<double>(0, (s, v) => s + v);

    // If all values are in [0, 1] and sum ≈ 1.0, they're already
    // probabilities — do NOT apply softmax again.
    if (allInUnitRange && (sum - 1.0).abs() < 0.15) {
      // Clamp to [0, 1] for safety.
      return scores.map((s) => s.clamp(0.0, 1.0)).toList();
    }

    return _softmax(scores);
  }

  /// Numeric-stable softmax.
  static List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) return const [];
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((l) => math.exp(l - maxLogit)).toList();
    final sum = exps.fold<double>(0, (s, e) => s + e);
    if (sum == 0) {
      return List.filled(logits.length, 1 / logits.length);
    }
    return exps.map((e) => e / sum).toList();
  }
}
