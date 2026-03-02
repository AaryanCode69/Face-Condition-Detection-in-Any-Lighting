import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:face_mood_light_detector/domain/enums/detection_state.dart';
import 'package:get/get.dart';

/// Phase 1 stub — fully implemented in Phase 3.
class FaceDetectionController extends GetxController {
  final detectionState = DetectionState.idle.obs;
  final faces = <FaceDetectionResult>[].obs;
  final faceCount = 0.obs;
  final confidence = 0.0.obs;


}
