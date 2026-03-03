import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:camera/camera.dart' as cam;
import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
// ignore: depend_on_referenced_packages, transitive dep of google_mlkit_face_detection
import 'package:google_mlkit_commons/google_mlkit_commons.dart' as mlkit;

/// Converts [cam.CameraImage] to [CameraFrame] and
/// [CameraFrame] to ML Kit [mlkit.InputImage].
class CameraImageMapper {
  const CameraImageMapper._();

  /// Must be fast — runs in the camera image stream callback.
  /// Heavy processing here blocks the native camera buffer pool.
  static CameraFrame toCameraFrame(
    cam.CameraImage image,
    int sensorOrientation,
  ) {
    final Uint8List bytes;
    final ImageFormat format;
    final int bytesPerRow;

    if (Platform.isAndroid) {
      bytes = _concatenatePlanes(image.planes);
      format = ImageFormat.nv21;
      bytesPerRow = image.planes.first.bytesPerRow;
    } else if (Platform.isIOS) {
      bytes = Uint8List.fromList(image.planes.first.bytes);
      format = ImageFormat.bgra8888;
      bytesPerRow = image.planes.first.bytesPerRow;
    } else {
      throw UnsupportedError(
        'Camera image conversion not supported on '
        '${Platform.operatingSystem}',
      );
    }

    return CameraFrame(
      bytes: bytes,
      width: image.width,
      height: image.height,
      rotation: sensorOrientation,
      format: format,
      timestamp: DateTime.now().microsecondsSinceEpoch,
      bytesPerRow: bytesPerRow,
    );
  }

  static mlkit.InputImage toMlKitInputImage(CameraFrame frame) {
    final rotation = _rotationFromDegrees(frame.rotation);
    final format = _mlkitFormat(frame.format);

    final metadata = mlkit.InputImageMetadata(
      size: Size(frame.width.toDouble(), frame.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: frame.bytesPerRow,
    );

    return mlkit.InputImage.fromBytes(
      bytes: frame.bytes,
      metadata: metadata,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Defensive copy so the camera buffer can be recycled immediately.
  static Uint8List _concatenatePlanes(List<cam.Plane> planes) {
    final totalLength = planes.fold<int>(
      0,
      (sum, plane) => sum + plane.bytes.length,
    );
    final result = Uint8List(totalLength);
    var offset = 0;
    for (final plane in planes) {
      result.setRange(offset, offset + plane.bytes.length, plane.bytes);
      offset += plane.bytes.length;
    }
    return result;
  }

  static mlkit.InputImageFormat _mlkitFormat(ImageFormat format) {
    switch (format) {
      case ImageFormat.nv21:
        return mlkit.InputImageFormat.nv21;
      case ImageFormat.bgra8888:
        return mlkit.InputImageFormat.bgra8888;
      case ImageFormat.yuv420:
        return mlkit.InputImageFormat.yuv420;
      case ImageFormat.rgb888:
        // ML Kit doesn't support RGB888 directly; fall back to NV21.
        return mlkit.InputImageFormat.nv21;
    }
  }

  static mlkit.InputImageRotation _rotationFromDegrees(int degrees) {
    switch (degrees) {
      case 0:
        return mlkit.InputImageRotation.rotation0deg;
      case 90:
        return mlkit.InputImageRotation.rotation90deg;
      case 180:
        return mlkit.InputImageRotation.rotation180deg;
      case 270:
        return mlkit.InputImageRotation.rotation270deg;
      default:
        return mlkit.InputImageRotation.rotation0deg;
    }
  }
}
