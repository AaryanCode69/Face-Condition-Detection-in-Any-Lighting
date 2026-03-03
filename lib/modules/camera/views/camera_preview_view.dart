import 'package:camera/camera.dart' as cam;
import 'package:face_mood_light_detector/domain/enums/camera_state.dart';
import 'package:face_mood_light_detector/modules/camera/controllers/camera_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CameraPreviewView extends GetView<AppCameraController> {
  const CameraPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.cameraState.value) {
        case CameraState.idle:
        case CameraState.initializing:
          return _buildLoading();
        case CameraState.ready:
          return _buildPreview(context);
        case CameraState.error:
          return _buildError(context);
      }
    });
  }

  Widget _buildLoading() {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white70),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final camCtrl = controller.cameraService.controller;
    if (camCtrl == null || !camCtrl.value.isInitialized) {
      return _buildLoading();
    }

    // camCtrl.value.aspectRatio is landscape-oriented (width/height).
    // In portrait mode we must invert it so the preview isn't stretched.
    final cameraAspectRatio = camCtrl.value.aspectRatio;
    final previewAspectRatio =
        MediaQuery.of(context).orientation == Orientation.portrait
            ? 1.0 / cameraAspectRatio
            : cameraAspectRatio;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: previewAspectRatio,
          child: cam.CameraPreview(camCtrl),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final hasPermission = controller.isPermissionGranted.value;
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              Text(
                hasPermission
                    ? 'Camera initialization failed'
                    : 'Camera permission required',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                hasPermission
                    ? 'Please restart the app or check device settings.'
                    : 'This app needs camera access to detect '
                        'face conditions.',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: controller.retryPermission,
                icon: const Icon(Icons.refresh),
                label: Text(
                  hasPermission ? 'Retry' : 'Grant Permission',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
