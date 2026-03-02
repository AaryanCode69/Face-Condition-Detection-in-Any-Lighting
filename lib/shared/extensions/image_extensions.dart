import 'dart:typed_data';

extension Uint8ListImageExtension on Uint8List {
  /// Defensive copy — pins camera frame bytes before the camera
  /// package reuses the underlying buffer.
  Uint8List toDefensiveCopy() => Uint8List.fromList(this);
}
