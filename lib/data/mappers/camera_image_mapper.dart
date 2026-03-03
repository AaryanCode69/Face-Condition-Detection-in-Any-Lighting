import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart' as cam;
import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';

/// Converts [cam.CameraImage] from the camera plugin into our
/// platform-agnostic [CameraFrame] domain entity.
///
/// Handles YUV_420_888 (Android) and BGRA8888 (iOS) formats.
/// Copies bytes defensively to prevent camera buffer reuse issues.
class CameraImageMapper {
  const CameraImageMapper._();

  /// Creates a [CameraFrame] from a raw [cam.CameraImage].
  ///
  /// [sensorOrientation] is the camera sensor orientation in degrees
  /// (0, 90, 180, 270).
  static CameraFrame toCameraFrame(
    cam.CameraImage image,
    int sensorOrientation,
  ) {
    final Uint8List bytes;
    final ImageFormat format;

    if (Platform.isAndroid) {
      // Android: YUV_420_888 — concatenate all plane bytes.
      bytes = _concatenatePlanes(image.planes);
      format = ImageFormat.nv21;
    } else if (Platform.isIOS) {
      // iOS: BGRA8888 — single plane, defensive copy.
      bytes = Uint8List.fromList(image.planes.first.bytes);
      format = ImageFormat.bgra8888;
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
    );
  }

  /// Concatenates all YUV plane bytes into a single buffer.
  /// Creates a defensive copy, preventing camera buffer reuse issues.
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
}
