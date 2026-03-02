enum LightingCondition {
  /// Overexposed regions likely.
  tooBright,

  /// Underexposed, noisy image.
  tooDim,

  balanced;

  String get label {
    switch (this) {
      case LightingCondition.tooBright:
        return 'Too Bright';
      case LightingCondition.tooDim:
        return 'Too Dim';
      case LightingCondition.balanced:
        return 'Balanced';
    }
  }

  String get suggestion {
    switch (this) {
      case LightingCondition.tooBright:
        return 'Lighting is too bright, results may be less accurate.';
      case LightingCondition.tooDim:
        return 'Move to a brighter area for better accuracy.';
      case LightingCondition.balanced:
        return 'Lighting conditions are good.';
    }
  }
}
