import 'dart:ui';

/// Maps face bounding boxes from image coordinates to screen/preview.
extension RectExtensions on Rect {
  Rect scaleToPreview({
    required Size imageSize,
    required Size previewSize,
  }) {
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
}
