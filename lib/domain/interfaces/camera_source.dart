import 'dart:ui';

import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';

class CameraConfig {
  const CameraConfig({
    this.useFrontCamera = true,
    this.targetResolution = const Size(1280, 720),
    this.enableAudio = false,
  });

  final bool useFrontCamera;
  final Size targetResolution;
  final bool enableAudio;
}

class CameraInfo {
  const CameraInfo({
    required this.sensorOrientation,
    required this.isFrontFacing,
    required this.previewSize,
  });

  final int sensorOrientation;
  final bool isFrontFacing;
  final Size previewSize;
}

abstract class CameraSource {
  Future<void> initialize(CameraConfig config);
  Stream<CameraFrame> get frameStream;
  Future<void> switchCamera();

  Future<void> setExposure(double value);

  Future<void> dispose();
  CameraInfo get info;
  bool get isStreaming;
}
