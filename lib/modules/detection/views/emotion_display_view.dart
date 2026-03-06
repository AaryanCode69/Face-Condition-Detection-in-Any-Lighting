import 'package:face_mood_light_detector/domain/enums/emotion_type.dart';
import 'package:face_mood_light_detector/modules/detection/controllers/emotion_controller.dart';
import 'package:face_mood_light_detector/shared/widgets/confidence_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Displays the primary emotion badge and confidence bars for all emotions.
class EmotionDisplayView extends GetView<EmotionController> {
  const EmotionDisplayView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isReady = controller.isModelReady.value;
      final isAnalyzing = controller.isAnalyzing.value;
      final smoothed = controller.smoothedEmotion.value;
      final confidences = controller.emotionConfidences;

      return Card(
        margin: const EdgeInsets.all(8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row: emoji + emotion label + status.
              _EmotionHeader(
                emotion: smoothed,
                isReady: isReady,
                isAnalyzing: isAnalyzing,
              ),

              if (isReady && isAnalyzing && confidences.isNotEmpty) ...[
                const Divider(height: 16),
                // Confidence bars for all emotions.
                ...EmotionType.values.map(
                  (type) => ConfidenceBar(
                    label: type.label,
                    value: confidences[type] ?? 0,
                    color: _emotionColor(type),
                  ),
                ),
              ],

              if (!isReady)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Loading emotion model...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  static Color _emotionColor(EmotionType type) {
    switch (type) {
      case EmotionType.happy:
        return const Color(0xFF4CAF50);
      case EmotionType.sad:
        return const Color(0xFF2196F3);
      case EmotionType.tired:
        return const Color(0xFF9E9E9E);
      case EmotionType.stressed:
        return const Color(0xFFF44336);
      case EmotionType.neutral:
        return const Color(0xFF607D8B);
    }
  }
}

class _EmotionHeader extends StatelessWidget {
  const _EmotionHeader({
    required this.emotion,
    required this.isReady,
    required this.isAnalyzing,
  });

  final EmotionType emotion;
  final bool isReady;
  final bool isAnalyzing;

  @override
  Widget build(BuildContext context) {
    final displayText = isReady && isAnalyzing
        ? emotion.label
        : isReady
            ? 'No face detected'
            : 'Emotion unavailable';

    final displayEmoji = isReady && isAnalyzing ? emotion.emoji : '...';

    return Row(
      children: [
        Text(
          displayEmoji,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (isReady && isAnalyzing)
                Text(
                  'Smoothed result',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
            ],
          ),
        ),
        if (!isReady)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}
