import 'dart:io';

/// Platform-specific ML runtime capabilities.
///
/// Stub in Phase 1; enhanced with device_info_plus in Phase 6.
class MlPlatformInfo {
  bool get supportsMlKit => Platform.isAndroid || Platform.isIOS;
  bool get supportsGpuDelegate => Platform.isAndroid || Platform.isIOS;

  /// NNAPI requires Android 8.1+.
  bool get supportsNnapi => Platform.isAndroid;
  bool get supportsCoreml => Platform.isIOS;
}
