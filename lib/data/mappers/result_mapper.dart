import 'dart:ui';

import 'package:face_mood_light_detector/data/models/raw_face_data.dart';
import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'
    as mlkit;

/// Converts raw ML Kit output to domain entities.
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
}
