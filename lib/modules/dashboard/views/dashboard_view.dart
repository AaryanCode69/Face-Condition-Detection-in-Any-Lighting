import 'package:face_mood_light_detector/modules/camera/controllers/camera_controller.dart';
import 'package:face_mood_light_detector/modules/camera/views/camera_preview_view.dart';
import 'package:face_mood_light_detector/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:face_mood_light_detector/modules/detection/controllers/face_detection_controller.dart';
import 'package:face_mood_light_detector/modules/detection/views/detection_overlay_view.dart';
import 'package:face_mood_light_detector/modules/detection/views/emotion_display_view.dart';
import 'package:face_mood_light_detector/shared/widgets/fps_counter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final faceController = Get.find<FaceDetectionController>();

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
                  const RepaintBoundary(
                    child: CameraPreviewView(),
                  ),

                  const DetectionOverlayView(),

                  // FPS counter overlay (top-left).
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Obx(
                      () => FpsCounter(
                        fps: controller.fps.value,
                        latencyMs:
                            faceController.processingTimeMs.value,
                      ),
                    ),
                  ),

                  // Face count badge (top-right).
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Obx(() {
                      final count = faceController.faceCount.value;
                      return _FaceCountBadge(count: count);
                    }),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Emotion analysis card.
                    const EmotionDisplayView(),

                    // Status info.
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Obx(
                        () => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: ${controller.overallStatus.value}',
                              style:
                                  Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'FPS: '
                                  '${controller.fps.value.toStringAsFixed(1)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Faces: '
                                  '${faceController.faceCount.value}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Latency: '
                                  '${faceController.processingTimeMs.value}'
                                  'ms',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small badge showing face count.
class _FaceCountBadge extends StatelessWidget {
  const _FaceCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: count > 0
            ? const Color(0xCC4CAF50)
            : const Color(0xCC757575),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            count > 0 ? Icons.face : Icons.face_outlined,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
