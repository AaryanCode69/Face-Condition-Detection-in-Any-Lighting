import 'dart:async';
import 'dart:collection';

import 'package:face_mood_light_detector/app/config/app_config.dart';
import 'package:face_mood_light_detector/core/logger/app_logger.dart';
import 'package:face_mood_light_detector/domain/entities/detection_frame.dart';
import 'package:face_mood_light_detector/domain/enums/emotion_type.dart';
import 'package:face_mood_light_detector/services/detection_pipeline_service.dart';
import 'package:get/get.dart';

/// Manages emotion analysis reactive state with temporal smoothing.
///
/// Subscribes to the detection pipeline's result stream and extracts
/// emotion data. Uses a sliding-window majority vote to prevent
/// rapid flickering of the displayed emotion label.
class EmotionController extends GetxController {
  EmotionController({
    required DetectionPipelineService pipelineService,
    required AppConfig appConfig,
    required AppLogger logger,
  })  : _pipelineService = pipelineService,
        _windowSize = appConfig.emotionSmoothingWindowSize,
        _logger = logger;

  final DetectionPipelineService _pipelineService;
  final int _windowSize;
  final AppLogger _logger;
  static const String _tag = 'EmotionCtrl';

  // -- Reactive state --

  final currentEmotion = EmotionType.neutral.obs;
  final emotionConfidences = <EmotionType, double>{}.obs;
  final isAnalyzing = false.obs;
  final smoothedEmotion = EmotionType.neutral.obs;

  /// Whether the emotion model has loaded and produced at least one result.
  final isModelReady = false.obs;

  // -- Internal --

  /// Sliding window of recent dominant emotions for majority vote.
  final Queue<EmotionType> _recentEmotions = Queue<EmotionType>();

  StreamSubscription<DetectionFrame>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _subscription = _pipelineService.resultStream.listen(
      _onDetectionFrame,
      onError: _onError,
    );
    _logger.debug(_tag, 'Listening for emotion results');
  }

  void _onDetectionFrame(DetectionFrame frame) {
    final emotion = frame.emotion;

    if (!emotion.isValid) {
      // No emotion data this frame (model not loaded or no face).
      isAnalyzing.value = false;
      return;
    }

    isAnalyzing.value = true;
    isModelReady.value = true;

    // Update raw (unsmoothed) values.
    currentEmotion.value = emotion.dominantEmotion;
    emotionConfidences.value =
        Map<EmotionType, double>.from(emotion.confidences);

    // Temporal smoothing: sliding window majority vote.
    _addToWindow(emotion.dominantEmotion);
    smoothedEmotion.value = _computeMajority();
  }

  void _addToWindow(EmotionType type) {
    _recentEmotions.addLast(type);
    while (_recentEmotions.length > _windowSize) {
      _recentEmotions.removeFirst();
    }
  }

  /// Returns the most frequent emotion in the sliding window.
  EmotionType _computeMajority() {
    if (_recentEmotions.isEmpty) return EmotionType.neutral;

    final counts = <EmotionType, int>{};
    for (final e in _recentEmotions) {
      counts[e] = (counts[e] ?? 0) + 1;
    }

    var best = EmotionType.neutral;
    var bestCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        bestCount = entry.value;
        best = entry.key;
      }
    }
    return best;
  }

  void _onError(Object error, StackTrace stackTrace) {
    _logger.warning(_tag, 'Emotion stream error: $error');
    isAnalyzing.value = false;
  }

  /// Resets the smoothing window (useful on camera switch).
  void resetSmoothing() {
    _recentEmotions.clear();
    smoothedEmotion.value = EmotionType.neutral;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
