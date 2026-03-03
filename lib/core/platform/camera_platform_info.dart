import 'dart:io';

/// Platform camera capabilities and device information.
class CameraPlatformInfo {
  bool get supportsImageStream => Platform.isAndroid || Platform.isIOS;

  /// Android = YUV_420_888, iOS = BGRA8888.
  String get expectedFormat {
    if (Platform.isAndroid) return 'YUV_420_888';
    if (Platform.isIOS) return 'BGRA8888';
    return 'unknown';
  }

  bool get hasFrontCamera => Platform.isAndroid || Platform.isIOS;

  /// Whether the default image stream format is YUV.
  bool get isYuvFormat => Platform.isAndroid;

  /// Whether the default image stream format is BGRA.
  bool get isBgraFormat => Platform.isIOS;

  /// Whether front camera preview needs horizontal mirroring for overlays.
  bool get frontCameraNeedsMirroring => true;

  /// The typical sensor orientation for the front camera.
  /// Android: varies by device (usually 270); iOS: usually 0.
  int get typicalFrontSensorRotation => Platform.isAndroid ? 270 : 0;
}
