import 'package:face_mood_light_detector/modules/detection/controllers/lighting_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LightingIndicatorView extends GetView<LightingController> {
  const LightingIndicatorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconForCondition(controller.lightingCondition.value.label),
                color: _colorForCondition(
                  controller.lightingCondition.value.label,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.lightingCondition.value.label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${controller.estimatedLux.value.toStringAsFixed(0)} lux',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForCondition(String label) {
    return switch (label) {
      'Too Bright' => Icons.wb_sunny,
      'Too Dim' => Icons.nightlight_round,
      _ => Icons.lightbulb_outline,
    };
  }

  Color _colorForCondition(String label) {
    return switch (label) {
      'Too Bright' => Colors.orange,
      'Too Dim' => Colors.blueGrey,
      _ => Colors.green,
    };
  }
}
