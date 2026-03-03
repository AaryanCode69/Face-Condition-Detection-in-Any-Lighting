import 'package:face_mood_light_detector/modules/settings/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader(context, 'Feature Flags'),
            SwitchListTile(
              title: const Text('Emotion Analysis'),
              subtitle: const Text('Enable emotion classification pipeline'),
              value: controller.enableEmotionAnalysis.value,
              onChanged: (v) => controller.enableEmotionAnalysis.value = v,
            ),
            SwitchListTile(
              title: const Text('Lighting Analysis'),
              subtitle: const Text('Enable lighting condition detection'),
              value: controller.enableLightingAnalysis.value,
              onChanged: (v) => controller.enableLightingAnalysis.value = v,
            ),
            const Divider(),
            _sectionHeader(context, 'Debug'),
            SwitchListTile(
              title: const Text('FPS Overlay'),
              subtitle: const Text('Show frames-per-second counter'),
              value: controller.enableFpsOverlay.value,
              onChanged: (v) => controller.enableFpsOverlay.value = v,
            ),
            SwitchListTile(
              title: const Text('Debug Logging'),
              subtitle: const Text('Verbose log output'),
              value: controller.enableDebugLogging.value,
              onChanged: (v) => controller.enableDebugLogging.value = v,
            ),
            const Divider(),
            _sectionHeader(context, 'Thresholds'),
            ListTile(
              title: const Text('Face Confidence'),
              subtitle: Slider(
                value: controller.faceConfidenceThreshold.value,
                onChanged: (v) =>
                    controller.faceConfidenceThreshold.value = v,
              ),
              trailing: Text(
                controller.faceConfidenceThreshold.value.toStringAsFixed(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
