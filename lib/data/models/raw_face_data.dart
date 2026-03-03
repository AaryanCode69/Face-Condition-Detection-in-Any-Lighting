import 'dart:ui';

class RawFaceData {
  const RawFaceData({
    required this.boundingBox,
    required this.landmarks,
    this.trackingId,
    this.headEulerAngleX,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    this.smilingProbability,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
  });

  final Rect boundingBox;
  final Map<String, Offset> landmarks;
  final int? trackingId;

  final double? headEulerAngleX;
  final double? headEulerAngleY;
  final double? headEulerAngleZ;

  final double? smilingProbability;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;

  @override
  String toString() =>
      'RawFaceData(box: $boundingBox, '
      'landmarks: ${landmarks.length}, '
      'trackingId: $trackingId)';
}
