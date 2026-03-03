import 'package:face_mood_light_detector/app/config/app_config.dart';
import 'package:face_mood_light_detector/app/config/feature_flags.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  late final AppConfig _config;
  late final FeatureFlags _flags;

  final enableEmotionAnalysis = true.obs;
  final enableLightingAnalysis = true.obs;
  final enableFpsOverlay = false.obs;
  final enableDebugLogging = false.obs;

  /// 0.0–1.0.
  final faceConfidenceThreshold = 0.5.obs;

  @override
  void onInit() {
    super.onInit();
    _config = Get.find<AppConfig>();
    _flags = Get.find<FeatureFlags>();

    enableEmotionAnalysis.value = _flags.enableEmotionAnalysis;
    enableLightingAnalysis.value = _flags.enableLightingAnalysis;
    enableFpsOverlay.value = _flags.enableFpsOverlay;
    enableDebugLogging.value = _flags.enableDebugLogging;
    faceConfidenceThreshold.value = _config.defaultFaceConfidenceThreshold;
  }
}
