import 'package:face_mood_light_detector/modules/camera/controllers/camera_controller.dart';
import 'package:face_mood_light_detector/modules/camera/views/camera_preview_view.dart';
import 'package:face_mood_light_detector/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:face_mood_light_detector/shared/widgets/fps_counter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Main screen composing camera preview, detection overlays, and status.
///
/// Phase 2 — camera preview + FPS counter + status panel.
/// Phase 3+ adds detection overlay, emotion display, lighting indicator.
class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Condition Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () =>
                Get.find<AppCameraController>().toggleCamera(),
            tooltip: 'Switch Camera',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed<void>('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Camera preview with overlay stack.
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Live camera preview.
                  const CameraPreviewView(),

                  // FPS counter overlay (top-left).
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Obx(
                      () => FpsCounter(fps: controller.fps.value),
                    ),
                  ),

                  // Phase 3: DetectionOverlayView goes here.
                  // Phase 4: EmotionDisplayView goes here.
                  // Phase 5: LightingIndicatorView goes here.
                ],
              ),
            ),

            // Status panel.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: ${controller.overallStatus.value}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'FPS: ${controller.fps.value.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.isFullPipelineReady.value
                            ? 'Pipeline: Ready'
                            : 'Pipeline: Not ready',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
