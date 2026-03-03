import 'package:face_mood_light_detector/modules/detection/controllers/emotion_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmotionDisplayView extends GetView<EmotionController> {
  const EmotionDisplayView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Emotion: ${controller.currentEmotion.value.label}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                controller.currentEmotion.value.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              if (controller.isAnalyzing.value)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
