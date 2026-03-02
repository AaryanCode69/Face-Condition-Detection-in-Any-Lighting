/// Wires camera frames through face detection → emotion → lighting stages.
///
/// Phase 1 stub — implemented in Phase 3 (face), 4 (emotion), 5 (lighting).
class DetectionPipelineService {
  bool get isRunning => false;

  Future<void> start() async {
    throw UnimplementedError('DetectionPipelineService not yet implemented');
  }

  void pause() {}

  void resume() {}

  Future<void> stop() async {}
}
