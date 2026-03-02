import 'package:face_mood_light_detector/modules/camera/controllers/camera_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Live camera preview widget.
///
/// Phase 1 stub — actual camera texture rendered in Phase 2.
class CameraPreviewView extends GetView<AppCameraController> {
  const CameraPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => controller.isReady.value
          ? const Center(
              child: Text(
                'Camera stream active (Phase 2)',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
