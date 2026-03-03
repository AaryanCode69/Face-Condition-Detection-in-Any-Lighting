import 'dart:io';

class CameraPlatformInfo {
  bool get supportsImageStream => Platform.isAndroid || Platform.isIOS;

  String get expectedFormat {
    if (Platform.isAndroid) return 'YUV_420_888';
    if (Platform.isIOS) return 'BGRA8888';
    return 'unknown';
  }

  bool get hasFrontCamera => Platform.isAndroid || Platform.isIOS;

  bool get isYuvFormat => Platform.isAndroid;
  bool get isBgraFormat => Platform.isIOS;
  bool get frontCameraNeedsMirroring => true;
  int get typicalFrontSensorRotation => Platform.isAndroid ? 270 : 0;
}
