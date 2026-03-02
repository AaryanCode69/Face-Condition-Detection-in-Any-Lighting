/// Phase 1 stub — implemented in Phase 6.
/// Spawns a long-lived isolate for TFLite inference to keep the
/// UI thread free from heavy compute.
class IsolateInferenceService {
  bool get isAlive => false;

  Future<void> start() async {
    throw UnimplementedError('IsolateInferenceService not yet implemented');
  }

  Future<void> stop() async {}
}
