import 'package:face_mood_light_detector/app/config/app_config.dart';
import 'package:face_mood_light_detector/core/error/error_handler.dart';
import 'package:face_mood_light_detector/core/logger/app_logger.dart';
import 'package:face_mood_light_detector/core/performance/frame_rate_monitor.dart';
import 'package:face_mood_light_detector/core/performance/inference_timer.dart';
import 'package:face_mood_light_detector/data/engines/mlkit_face_detection_engine.dart';
import 'package:face_mood_light_detector/data/repositories/detection_repository.dart';
import 'package:face_mood_light_detector/domain/interfaces/face_detection_engine.dart';
import 'package:face_mood_light_detector/modules/camera/controllers/camera_controller.dart';
import 'package:face_mood_light_detector/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:face_mood_light_detector/modules/detection/controllers/face_detection_controller.dart';
import 'package:face_mood_light_detector/services/camera_service.dart';
import 'package:face_mood_light_detector/services/detection_pipeline_service.dart';
import 'package:face_mood_light_detector/services/frame_throttle_service.dart';
import 'package:get/get.dart';

class DetectionBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..lazyPut<CameraService>(
        () => CameraService(
          logger: Get.find<AppLogger>(),
          frameRateMonitor: Get.find<FrameRateMonitor>(),
        ),
      )
      ..lazyPut<FrameThrottleService>(
        () => FrameThrottleService(
          targetFps: Get.find<AppConfig>().defaultTargetFps,
        ),
      )
      ..lazyPut<InferenceTimer>(InferenceTimer.new);

    // ignore: cascade_invocations
    Get.lazyPut<FaceDetectionEngine>(MlKitFaceDetectionEngine.new);

    // ignore: cascade_invocations
    Get.lazyPut<DetectionRepository>(
      () => DetectionRepository(
        faceEngine: Get.find<FaceDetectionEngine>(),
        logger: Get.find<AppLogger>(),
      ),
    );

    // ignore: cascade_invocations
    Get.lazyPut<DetectionPipelineService>(
      () => DetectionPipelineService(
        cameraService: Get.find<CameraService>(),
        detectionRepository: Get.find<DetectionRepository>(),
        throttleService: Get.find<FrameThrottleService>(),
        inferenceTimer: Get.find<InferenceTimer>(),
        logger: Get.find<AppLogger>(),
      ),
    );

    // ignore: cascade_invocations
    Get
      ..lazyPut<AppCameraController>(
        () => AppCameraController(
          cameraService: Get.find<CameraService>(),
          logger: Get.find<AppLogger>(),
          errorHandler: Get.find<ErrorHandler>(),
        ),
      )
      ..lazyPut<FaceDetectionController>(
        () => FaceDetectionController(
          pipelineService: Get.find<DetectionPipelineService>(),
          logger: Get.find<AppLogger>(),
        ),
      )
      ..lazyPut<DashboardController>(DashboardController.new);
  }
}
