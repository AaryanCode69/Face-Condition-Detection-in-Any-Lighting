import 'dart:ui';

extension RectExtensions on Rect {
  Rect scaleToPreview({required Size imageSize, required Size previewSize}) {
    final scaleX = previewSize.width / imageSize.width;
    final scaleY = previewSize.height / imageSize.height;

    return Rect.fromLTRB(
      left * scaleX,
      top * scaleY,
      right * scaleX,
      bottom * scaleY,
    );
  }

  Rect mirrorHorizontally(double containerWidth) {
    return Rect.fromLTRB(
      containerWidth - right,
      top,
      containerWidth - left,
      bottom,
    );
  }

  /// Transforms from image space to screen space,
  /// handling rotation, scaling, and front camera mirroring.
  Rect toScreenRect({
    required Size imageSize,
    required Size screenSize,
    required int sensorOrientation,
    required bool isFrontCamera,
  }) {
    final rotatedImageSize = _rotatedSize(imageSize, sensorOrientation);

    final rotated = _rotateRect(
      rect: this,
      imageSize: imageSize,
      rotation: sensorOrientation,
    );

    final scaled = rotated.scaleToPreview(
      imageSize: rotatedImageSize,
      previewSize: screenSize,
    );

    if (isFrontCamera) {
      return scaled.mirrorHorizontally(screenSize.width);
    }

    return scaled;
  }

  static Rect _rotateRect({
    required Rect rect,
    required Size imageSize,
    required int rotation,
  }) {
    switch (rotation) {
      case 0:
        return rect;
      case 90:
        return Rect.fromLTRB(
          rect.top,
          imageSize.width - rect.right,
          rect.bottom,
          imageSize.width - rect.left,
        );
      case 180:
        return Rect.fromLTRB(
          imageSize.width - rect.right,
          imageSize.height - rect.bottom,
          imageSize.width - rect.left,
          imageSize.height - rect.top,
        );
      case 270:
        return Rect.fromLTRB(
          imageSize.height - rect.bottom,
          rect.left,
          imageSize.height - rect.top,
          rect.right,
        );
      default:
        return rect;
    }
  }

  static Size _rotatedSize(Size size, int rotation) {
    if (rotation == 90 || rotation == 270) {
      return Size(size.height, size.width);
    }
    return size;
  }
}
