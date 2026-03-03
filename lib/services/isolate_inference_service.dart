/// Spawns a long-lived isolate for TFLite inference.
class IsolateInferenceService {
  bool get isAlive => false;

  Future<void> start() async {
    throw UnimplementedError('IsolateInferenceService not yet implemented');
  }

  Future<void> stop() async {}
}
