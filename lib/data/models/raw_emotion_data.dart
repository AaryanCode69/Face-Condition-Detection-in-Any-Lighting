/// Raw output DTO from the TFLite emotion classifier.
///
/// Contains the raw float array output from the model before mapping
/// to domain `EmotionResult`.
class RawEmotionData {
  const RawEmotionData({
    required this.outputScores,
    required this.inferenceTimeMs,
  });

  /// Raw model output — one float per emotion class.
  ///
  /// Standard FER-2013 model outputs 7 classes in this order:
  /// [angry, disgust, fear, happy, sad, surprise, neutral]
  final List<double> outputScores;

  /// How long inference took in milliseconds.
  final int inferenceTimeMs;

  /// Returns the index of the highest-scoring class.
  int get dominantIndex {
    if (outputScores.isEmpty) return -1;
    var maxIdx = 0;
    for (var i = 1; i < outputScores.length; i++) {
      if (outputScores[i] > outputScores[maxIdx]) {
        maxIdx = i;
      }
    }
    return maxIdx;
  }

  double get maxScore =>
      outputScores.isEmpty ? 0 : outputScores[dominantIndex];

  @override
  String toString() =>
      'RawEmotionData(scores: ${outputScores.length} classes, '
      'max: ${maxScore.toStringAsFixed(3)}, '
      'inference: ${inferenceTimeMs}ms)';
}
