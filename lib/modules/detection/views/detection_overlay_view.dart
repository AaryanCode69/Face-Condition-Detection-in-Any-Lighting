import 'package:face_mood_light_detector/modules/detection/controllers/face_detection_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Canvas overlay that draws bounding boxes and landmarks over the preview.
///
/// Phase 1 stub — CustomPainter wired in Phase 3.
class DetectionOverlayView extends GetView<FaceDetectionController> {
  const DetectionOverlayView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => controller.faces.isEmpty
          ? const SizedBox.shrink()
          : Center(
              child: Text(
                '${controller.faceCount.value} face(s) detected',
                style: const TextStyle(color: Colors.greenAccent),
              ),
            ),
    );
  }
}
