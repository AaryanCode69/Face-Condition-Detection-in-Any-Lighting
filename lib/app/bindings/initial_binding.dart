import 'package:face_mood_light_detector/app/config/app_config.dart';
import 'package:face_mood_light_detector/app/config/feature_flags.dart';
import 'package:face_mood_light_detector/core/error/error_handler.dart';
import 'package:face_mood_light_detector/core/logger/app_logger.dart';
import 'package:face_mood_light_detector/core/performance/frame_rate_monitor.dart';
import 'package:get/get.dart';

/// All bindings here are permanent — they survive the entire app lifecycle.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..put<AppConfig>(const AppConfig(), permanent: true)
      ..put<FeatureFlags>(const FeatureFlags(), permanent: true)
      ..put<AppLogger>(AppLogger(), permanent: true);

    // Separate cascade: ErrorHandler depends on AppLogger registered above.
    // ignore: cascade_invocations
    Get
      ..put<ErrorHandler>(
        ErrorHandler(logger: Get.find<AppLogger>()),
        permanent: true,
      )
      ..put<FrameRateMonitor>(FrameRateMonitor(), permanent: true);
  }
}
