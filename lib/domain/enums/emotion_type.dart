enum EmotionType {
  happy,
  sad,
  tired,
  stressed,
  neutral;

  String get label {
    switch (this) {
      case EmotionType.happy:
        return 'Happy';
      case EmotionType.sad:
        return 'Sad';
      case EmotionType.tired:
        return 'Tired';
      case EmotionType.stressed:
        return 'Stressed';
      case EmotionType.neutral:
        return 'Neutral';
    }
  }

  String get emoji {
    switch (this) {
      case EmotionType.happy:
        return '😊';
      case EmotionType.sad:
        return '😢';
      case EmotionType.tired:
        return '😴';
      case EmotionType.stressed:
        return '😰';
      case EmotionType.neutral:
        return '😐';
    }
  }
}
