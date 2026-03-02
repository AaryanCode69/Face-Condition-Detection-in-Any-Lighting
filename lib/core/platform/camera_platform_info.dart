import 'dart:io';

/// Platform camera capabilities. Stub in Phase 1; real data in Phase 2.
class CameraPlatformInfo {
  bool get supportsImageStream => Platform.isAndroid || Platform.isIOS;

  /// Android = YUV_420_888, iOS = BGRA8888.
  String get expectedFormat {
    if (Platform.isAndroid) return 'YUV_420_888';
    if (Platform.isIOS) return 'BGRA8888';
    return 'unknown';
  }

  bool get hasFrontCamera => Platform.isAndroid || Platform.isIOS;
}
