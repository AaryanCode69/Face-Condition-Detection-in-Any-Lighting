import 'dart:ui' as ui;

import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:face_mood_light_detector/modules/camera/controllers/camera_controller.dart';
import 'package:face_mood_light_detector/modules/detection/controllers/face_detection_controller.dart';
import 'package:face_mood_light_detector/shared/extensions/rect_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Canvas overlay that draws bounding boxes and face info over the preview.
class DetectionOverlayView extends GetView<FaceDetectionController> {
  const DetectionOverlayView({super.key});

  @override
  Widget build(BuildContext context) {
    final cameraController = Get.find<AppCameraController>();

    return RepaintBoundary(
      child: Obx(() {
        final faces = controller.faces;
        if (faces.isEmpty) return const SizedBox.shrink();

        final previewSize = cameraController.previewSize.value;
        final isFront = cameraController.isFrontCamera.value;
        final sensorOrientation =
            cameraController.cameraService.sensorOrientation;

        return CustomPaint(
          painter: _FaceOverlayPainter(
            faces: faces.toList(),
            imageSize: previewSize != null
                ? Size(previewSize.height, previewSize.width)
                : const Size(720, 1280),
            sensorOrientation: sensorOrientation,
            isFrontCamera: isFront,
          ),
          size: Size.infinite,
        );
      }),
    );
  }
}

class _FaceOverlayPainter extends CustomPainter {
  _FaceOverlayPainter({
    required this.faces,
    required this.imageSize,
    required this.sensorOrientation,
    required this.isFrontCamera,
  });

  final List<FaceDetectionResult> faces;
  final Size imageSize;
  final int sensorOrientation;
  final bool isFrontCamera;

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final dotPaint = Paint()
      ..color = const Color(0xFF81C784)
      ..style = PaintingStyle.fill;

    for (final face in faces) {
      final screenRect = face.boundingBox.toScreenRect(
        imageSize: imageSize,
        screenSize: size,
        sensorOrientation: sensorOrientation,
        isFrontCamera: isFrontCamera,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(screenRect, const Radius.circular(8)),
        boxPaint,
      );

      _drawConfidenceLabel(
        canvas,
        screenRect,
        face.confidence,
        face.trackingId,
      );

      for (final landmark in face.landmarks) {
        final screenPoint = Offset(
          landmark.position.dx,
          landmark.position.dy,
        ).transform(
          imageSize: imageSize,
          screenSize: size,
          sensorOrientation: sensorOrientation,
          isFrontCamera: isFrontCamera,
        );
        canvas.drawCircle(screenPoint, 3, dotPaint);
      }
    }
  }

  void _drawConfidenceLabel(
    Canvas canvas,
    Rect screenRect,
    double confidence,
    int? trackingId,
  ) {
    final text = trackingId != null
        ? 'ID:$trackingId  ${(confidence * 100).toStringAsFixed(0)}%'
        : '${(confidence * 100).toStringAsFixed(0)}%';

    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    )
      ..pushStyle(
        ui.TextStyle(
          color: const Color(0xFFFFFFFF),
          background: Paint()..color = const Color(0xCC4CAF50),
        ),
      )
      ..addText(' $text ');

    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 200));

    final labelY = screenRect.top - paragraph.height - 2;
    canvas.drawParagraph(
      paragraph,
      Offset(screenRect.left, labelY.clamp(0, double.infinity)),
    );
  }

  @override
  bool shouldRepaint(_FaceOverlayPainter oldDelegate) {
    return faces != oldDelegate.faces ||
        sensorOrientation != oldDelegate.sensorOrientation ||
        isFrontCamera != oldDelegate.isFrontCamera;
  }
}

extension _OffsetTransform on Offset {
  Offset transform({
    required Size imageSize,
    required Size screenSize,
    required int sensorOrientation,
    required bool isFrontCamera,
  }) {

    final pointRect = Rect.fromLTWH(dx, dy, 0, 0);
    final transformed = pointRect.toScreenRect(
      imageSize: imageSize,
      screenSize: screenSize,
      sensorOrientation: sensorOrientation,
      isFrontCamera: isFrontCamera,
    );
    return transformed.topLeft;
  }
}
