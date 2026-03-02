/// Engines throw typed exceptions; services catch them and
/// map them to `Failure` sealed classes.
sealed class AppException implements Exception {
  const AppException({required this.message, this.stackTrace});

  final String message;
  final StackTrace? stackTrace;

  @override
  String toString() => '$_typeName: $message';

  String get _typeName {
    if (this is CameraPermissionException) return 'CameraPermissionException';
    if (this is CameraUnavailableException) return 'CameraUnavailableException';
    if (this is CameraInitException) return 'CameraInitException';
    if (this is ModelLoadException) return 'ModelLoadException';
    if (this is InferenceException) return 'InferenceException';
    if (this is IsolateCrashException) return 'IsolateCrashException';
    if (this is IsolateTimeoutException) return 'IsolateTimeoutException';
    if (this is FrameProcessingException) return 'FrameProcessingException';
    return 'AppException';
  }
}

// Camera exceptions

class CameraPermissionException extends AppException {
  const CameraPermissionException({
    super.message = 'Camera permission denied',
  });
}

class CameraUnavailableException extends AppException {
  const CameraUnavailableException({
    super.message = 'Camera hardware unavailable',
    super.stackTrace,
  });
}

class CameraInitException extends AppException {
  const CameraInitException({
    super.message = 'Camera initialization failed',
    super.stackTrace,
  });
}

// ML Engine exceptions

class ModelLoadException extends AppException {
  const ModelLoadException({
    super.message = 'Failed to load ML model',
    super.stackTrace,
  });
}

class InferenceException extends AppException {
  const InferenceException({
    super.message = 'ML inference failed',
    super.stackTrace,
  });
}

// Isolate exceptions

class IsolateCrashException extends AppException {
  const IsolateCrashException({
    super.message = 'Background isolate crashed',
    super.stackTrace,
  });
}

class IsolateTimeoutException extends AppException {
  const IsolateTimeoutException({
    super.message = 'Isolate communication timeout',
    super.stackTrace,
  });
}

// Frame processing exceptions

/// Corrupt or unsupported camera frame data.
class FrameProcessingException extends AppException {
  const FrameProcessingException({
    super.message = 'Frame processing error',
    super.stackTrace,
  });
}
