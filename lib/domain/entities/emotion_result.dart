import 'package:face_mood_light_detector/domain/enums/emotion_type.dart';

class EmotionResult {
  const EmotionResult({
    required this.dominantEmotion,
    required this.confidences,
  });

  const EmotionResult.unknown()
      : dominantEmotion = EmotionType.neutral,
        confidences = const {};

  final EmotionType dominantEmotion;

  final Map<EmotionType, double> confidences;

  double get dominantConfidence => confidences[dominantEmotion] ?? 0;
  bool get isValid => confidences.isNotEmpty;

  @override
  String toString() =>
      'EmotionResult(${dominantEmotion.label}: '
      '${(dominantConfidence * 100).toStringAsFixed(1)}%)';
}
