import 'package:get/get.dart';

/// Composes detection sub-states for the main dashboard UI.
/// Does NOT duplicate sub-controller state; only aggregates.
///
/// Phase 1 stub — reads from sub-controllers added in later phases.
class DashboardController extends GetxController {
  final isFullPipelineReady = false.obs;
  final fps = 0.0.obs;
  final overallStatus = 'Initializing...'.obs;

  @override
  void onInit() {
    super.onInit();
    // Phase 1: No sub-controllers to aggregate yet.
    overallStatus.value = 'Phase 1: Architecture scaffold ready';
  }

}
