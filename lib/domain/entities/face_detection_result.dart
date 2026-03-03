import 'dart:typed_data';
import 'dart:ui';

class FaceDetectionResult {
  const FaceDetectionResult({
    required this.boundingBox,
    required this.confidence,
    this.landmarks = const [],
    this.trackingId,
  });

  final Rect boundingBox;

  /// 0.0–1.0.
  final double confidence;
  final List<Landmark> landmarks;
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
class CameraFrame {
  const CameraFrame({
    required this.bytes,
    required this.width,
    required this.height,
    required this.rotation,
    required this.format,
    required this.timestamp,
    required this.bytesPerRow,
  });

  final Uint8List bytes;
  final int width;
  final int height;

  /// Clockwise degrees (0, 90, 180, 270).
  final int rotation;
  final ImageFormat format;
  final int timestamp;

  /// Row stride from camera plane[0]; required by ML Kit.
  final int bytesPerRow;
}

enum ImageFormat {
  nv21,
  bgra8888,
  rgb888,
  yuv420,
}

class FaceCrop {
  const FaceCrop({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}
