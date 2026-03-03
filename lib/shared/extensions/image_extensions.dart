import 'dart:typed_data';

extension Uint8ListImageExtension on Uint8List {
  Uint8List toDefensiveCopy() => Uint8List.fromList(this);
}
