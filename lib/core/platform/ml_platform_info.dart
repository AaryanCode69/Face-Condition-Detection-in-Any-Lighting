import 'dart:io';

class MlPlatformInfo {
  bool get supportsMlKit => Platform.isAndroid || Platform.isIOS;
  bool get supportsGpuDelegate => Platform.isAndroid || Platform.isIOS;

  bool get supportsNnapi => Platform.isAndroid;
  bool get supportsCoreml => Platform.isIOS;
}
