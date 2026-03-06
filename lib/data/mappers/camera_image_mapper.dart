import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Rect, Size;

import 'package:camera/camera.dart' as cam;
import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
// ignore: depend_on_referenced_packages, transitive dep of google_mlkit_face_detection
import 'package:google_mlkit_commons/google_mlkit_commons.dart' as mlkit;

/// Converts [cam.CameraImage] to [CameraFrame],
/// [CameraFrame] to ML Kit [mlkit.InputImage], and
/// extracts face crops for the TFLite emotion classifier.
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

  // ---------------------------------------------------------------------------
  // Face crop extraction for the TFLite emotion classifier
  // ---------------------------------------------------------------------------

  /// Default TFLite emotion model input size (FER-2013 standard).
  static const int kEmotionModelInputSize = 48;

  /// Extracts the face region from [frame] using [boundingBox],
  /// resizes to [targetSize]×[targetSize] grayscale, and normalises
  /// pixel values to 0-1.
  ///
  /// Returns a [FaceCrop] with float-normalised grayscale bytes
  /// (4 bytes per pixel — Float32).
  static FaceCrop extractFaceCrop(
    CameraFrame frame,
    Rect boundingBox, {
    int targetSize = kEmotionModelInputSize,
    double padding = 0.15,
  }) {
    // 1. Decode NV21/BGRA to grayscale luminance buffer.
    final grayscale = _extractGrayscale(frame);

    // 2. Compute padded bounding box, clamped to image bounds.
    final padded = _paddedRect(
      boundingBox,
      frame.width.toDouble(),
      frame.height.toDouble(),
      padding,
    );

    // 3. Crop the face region.
    final cropped = _cropGrayscale(
      grayscale,
      frame.width,
      frame.height,
      padded,
    );

    // 4. Resize to model input dimensions with bilinear interpolation.
    final resized = _resizeBilinear(
      cropped,
      padded.width.round(),
      padded.height.round(),
      targetSize,
      targetSize,
    );

    // 5. Normalise to [0.0, 1.0] and pack as Float32.
    final normalised = _normaliseToFloat32(resized);

    return FaceCrop(
      bytes: normalised,
      width: targetSize,
      height: targetSize,
    );
  }

  /// Extracts Y (luminance) channel from the frame.
  /// NV21: first W*H bytes are Y.
  /// BGRA: manually compute from RGB.
  static Uint8List _extractGrayscale(CameraFrame frame) {
    final pixelCount = frame.width * frame.height;

    switch (frame.format) {
      case ImageFormat.nv21:
      case ImageFormat.yuv420:
        // First plane is Y channel.
        return Uint8List.fromList(
          frame.bytes.buffer.asUint8List(0, pixelCount),
        );

      case ImageFormat.bgra8888:
        final gray = Uint8List(pixelCount);
        for (var i = 0; i < pixelCount; i++) {
          final b = frame.bytes[i * 4];
          final g = frame.bytes[i * 4 + 1];
          final r = frame.bytes[i * 4 + 2];
          // ITU-R BT.601 luminance.
          gray[i] = ((0.299 * r) + (0.587 * g) + (0.114 * b)).round();
        }
        return gray;

      case ImageFormat.rgb888:
        final gray = Uint8List(pixelCount);
        for (var i = 0; i < pixelCount; i++) {
          final r = frame.bytes[i * 3];
          final g = frame.bytes[i * 3 + 1];
          final b = frame.bytes[i * 3 + 2];
          gray[i] = ((0.299 * r) + (0.587 * g) + (0.114 * b)).round();
        }
        return gray;
    }
  }

  /// Pads a bounding box by [padding] fraction, clamped to image.
  static Rect _paddedRect(
    Rect box,
    double imgW,
    double imgH,
    double padding,
  ) {
    final padX = box.width * padding;
    final padY = box.height * padding;

    final left = (box.left - padX).clamp(0.0, imgW);
    final top = (box.top - padY).clamp(0.0, imgH);
    final right = (box.right + padX).clamp(0.0, imgW);
    final bottom = (box.bottom + padY).clamp(0.0, imgH);

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Crops a grayscale buffer to [rect].
  static Uint8List _cropGrayscale(
    Uint8List gray,
    int imgW,
    int imgH,
    Rect rect,
  ) {
    final x0 = rect.left.round().clamp(0, imgW - 1);
    final y0 = rect.top.round().clamp(0, imgH - 1);
    final x1 = rect.right.round().clamp(0, imgW);
    final y1 = rect.bottom.round().clamp(0, imgH);

    final cropW = x1 - x0;
    final cropH = y1 - y0;

    if (cropW <= 0 || cropH <= 0) return Uint8List(0);

    final result = Uint8List(cropW * cropH);
    for (var row = 0; row < cropH; row++) {
      final srcStart = (y0 + row) * imgW + x0;
      final dstStart = row * cropW;
      result.setRange(dstStart, dstStart + cropW, gray, srcStart);
    }
    return result;
  }

  /// Bilinear interpolation resize of a grayscale buffer.
  static Uint8List _resizeBilinear(
    Uint8List src,
    int srcW,
    int srcH,
    int dstW,
    int dstH,
  ) {
    if (srcW <= 0 || srcH <= 0) return Uint8List(dstW * dstH);

    final result = Uint8List(dstW * dstH);
    final xRatio = srcW / dstW;
    final yRatio = srcH / dstH;

    for (var y = 0; y < dstH; y++) {
      final srcY = y * yRatio;
      final y0 = srcY.floor().clamp(0, srcH - 1);
      final y1 = math.min(y0 + 1, srcH - 1);
      final yLerp = srcY - y0;

      for (var x = 0; x < dstW; x++) {
        final srcX = x * xRatio;
        final x0 = srcX.floor().clamp(0, srcW - 1);
        final x1 = math.min(x0 + 1, srcW - 1);
        final xLerp = srcX - x0;

        final topLeft = src[y0 * srcW + x0].toDouble();
        final topRight = src[y0 * srcW + x1].toDouble();
        final bottomLeft = src[y1 * srcW + x0].toDouble();
        final bottomRight = src[y1 * srcW + x1].toDouble();

        final top = topLeft + (topRight - topLeft) * xLerp;
        final bottom = bottomLeft + (bottomRight - bottomLeft) * xLerp;
        final value = top + (bottom - top) * yLerp;

        result[y * dstW + x] = value.round().clamp(0, 255);
      }
    }
    return result;
  }

  /// Converts a grayscale [Uint8List] to normalised [0.0–1.0] Float32.
  static Uint8List _normaliseToFloat32(Uint8List grayscale) {
    final floatList = Float32List(grayscale.length);
    for (var i = 0; i < grayscale.length; i++) {
      floatList[i] = grayscale[i] / 255.0;
    }
    return floatList.buffer.asUint8List();
  }
}
