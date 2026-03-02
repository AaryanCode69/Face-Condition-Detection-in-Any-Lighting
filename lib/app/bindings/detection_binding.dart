import 'package:face_mood_light_detector/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:get/get.dart';

/// Phase 1: Only DashboardController.
/// Later phases add: Camera (P2), FaceDetection (P3), Emotion (P4),
/// Lighting (P5), Isolate inference (P6).
class DetectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(DashboardController.new);
  }
}
