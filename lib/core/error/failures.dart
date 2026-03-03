/// Failures represent expected error conditions the app can handle gracefully.
/// Services catch exceptions and map them to these sealed failure types.
sealed class Failure {
  const Failure({required this.message, this.stackTrace});

  final String message;
  final StackTrace? stackTrace;

  @override
  String toString() => '$_typeName: $message';

  String get _typeName {
    if (this is CameraPermissionFailure) return 'CameraPermissionFailure';
    if (this is CameraUnavailableFailure) return 'CameraUnavailableFailure';
    if (this is CameraInitFailure) return 'CameraInitFailure';
    if (this is ModelLoadFailure) return 'ModelLoadFailure';
    if (this is InferenceFailure) return 'InferenceFailure';
    if (this is IsolateCrashFailure) return 'IsolateCrashFailure';
    if (this is FrameProcessingFailure) return 'FrameProcessingFailure';
    if (this is ResourcePressureFailure) return 'ResourcePressureFailure';
    return 'Failure';
  }
}

class CameraPermissionFailure extends Failure {
  const CameraPermissionFailure({super.message = 'Camera permission denied'});
}

class CameraUnavailableFailure extends Failure {
  const CameraUnavailableFailure({
    super.message = 'Camera unavailable',
    super.stackTrace,
  });
}

class CameraInitFailure extends Failure {
  const CameraInitFailure({
    super.message = 'Camera initialization failed',
    super.stackTrace,
  });
}

class ModelLoadFailure extends Failure {
  const ModelLoadFailure({
    super.message = 'Model failed to load',
    super.stackTrace,
  });
}

class InferenceFailure extends Failure {
  const InferenceFailure({
    super.message = 'Inference failed',
    super.stackTrace,
  });
}

class IsolateCrashFailure extends Failure {
  const IsolateCrashFailure({
    super.message = 'Inference isolate crashed',
    super.stackTrace,
  });
}

class FrameProcessingFailure extends Failure {
  const FrameProcessingFailure({
    super.message = 'Frame processing error',
    super.stackTrace,
  });
}

class ResourcePressureFailure extends Failure {
  const ResourcePressureFailure({
    super.message = 'System resource pressure',
    super.stackTrace,
  });
}
