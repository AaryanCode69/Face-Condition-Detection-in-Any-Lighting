import 'dart:typed_data';
import 'dart:ui';

class FaceDetectionResult {
  const FaceDetectionResult({
    required this.boundingBox,
    required this.confidence,
    this.landmarks = const [],
    this.trackingId,
  });

  /// In image coordinates (not screen/preview).
  final Rect boundingBox;

  /// 0.0–1.0.
  final double confidence;
  final List<Landmark> landmarks;

  /// `null` if tracking is not enabled.
  final int? trackingId;

  @override
  String toString() =>
      'FaceDetectionResult(box: $boundingBox, confidence: '
      '${confidence.toStringAsFixed(2)}, '
      'landmarks: ${landmarks.length}, trackingId: $trackingId)';
}

class Landmark {
  const Landmark({
    required this.type,
    required this.position,
  });

  final LandmarkType type;

  /// In image coordinates.
  final Offset position;
}

enum LandmarkType {
  leftEye,
  rightEye,
  noseBase,
  leftMouth,
  rightMouth,
  leftEar,
  rightEar,
  leftCheek,
  rightCheek,
  bottomMouth,
}

/// Platform-agnostic camera frame DTO.
/// All camera-specific formats are converted into this
/// before entering the detection pipeline.
class CameraFrame {
  const CameraFrame({
    required this.bytes,
    required this.width,
    required this.height,
    required this.rotation,
    required this.format,
    required this.timestamp,
  });

  final Uint8List bytes;
  final int width;
  final int height;

  /// Clockwise degrees (0, 90, 180, 270) to make image upright.
  final int rotation;
  final ImageFormat format;

  /// In microseconds.
  final int timestamp;
}

enum ImageFormat {
  /// Android default.
  nv21,

  /// iOS default.
  bgra8888,

  rgb888,
  yuv420,
}

/// Cropped, resized face image ready for emotion analysis.
class FaceCrop {
  const FaceCrop({
    required this.bytes,
    required this.width,
    required this.height,
  });

  /// RGB pixels; may be normalized depending on pipeline stage.
  final Uint8List bytes;
  final int width;
  final int height;
}
