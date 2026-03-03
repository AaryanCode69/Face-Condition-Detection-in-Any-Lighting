import 'package:face_mood_light_detector/core/error/failures.dart';
import 'package:face_mood_light_detector/core/logger/app_logger.dart';

class ErrorHandler {
  ErrorHandler({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;

  int _transientErrorCount = 0;
  DateTime _transientWindowStart = DateTime.now();

  void handleCameraError(Failure failure) {
    _logger.error('Camera', failure.message, failure.stackTrace);
  }

  void handleInferenceError(InferenceFailure failure) {
    _logger.error('Inference', failure.message, failure.stackTrace);
  }

  void handleIsolateError(IsolateCrashFailure failure) {
    _logger.error('Isolate', failure.message, failure.stackTrace);
  }

  /// Escalates to critical if >10 transient errors within 5 seconds.
  void handleTransientError(FrameProcessingFailure failure) {
    final now = DateTime.now();
    if (now.difference(_transientWindowStart).inSeconds > 5) {
      _transientErrorCount = 0;
      _transientWindowStart = now;
    }

    _transientErrorCount++;

    if (_transientErrorCount > 10) {
      _logger.error(
        'Transient',
        'Escalated: ${failure.message} '
            '($_transientErrorCount errors in 5s)',
        failure.stackTrace,
      );
    } else {
      _logger.warning('Transient', failure.message);
    }
  }

  void handleGenericError(Failure failure) {
    _logger.error('Generic', failure.message, failure.stackTrace);
  }
}
