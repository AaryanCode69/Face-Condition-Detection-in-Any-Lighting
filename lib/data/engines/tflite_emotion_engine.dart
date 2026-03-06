import 'package:face_mood_light_detector/core/error/exceptions.dart';
import 'package:face_mood_light_detector/core/logger/app_logger.dart';
import 'package:face_mood_light_detector/data/mappers/result_mapper.dart';
import 'package:face_mood_light_detector/data/models/raw_emotion_data.dart';
import 'package:face_mood_light_detector/domain/entities/emotion_result.dart';
import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:face_mood_light_detector/domain/enums/emotion_type.dart';
import 'package:face_mood_light_detector/domain/interfaces/emotion_analyzer.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Concrete [EmotionAnalyzer] implementation using TensorFlow Lite.
///
/// Encapsulates all TFLite imports — the rest of the app codes against
/// the [EmotionAnalyzer] interface and never imports this package.
class TfliteEmotionEngine implements EmotionAnalyzer {
  TfliteEmotionEngine({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;
  static const String _tag = 'TFLiteEmotion';

  Interpreter? _interpreter;
  bool _isLoaded = false;

  /// Expected model input shape: [1, 48, 48, 1].
  static const int _inputSize = 48;

  /// Determined dynamically from the model's output tensor shape.
  int _numClasses = 7;

  @override
  bool get isModelLoaded => _isLoaded;

  @override
  List<EmotionType> get supportedEmotions => EmotionType.values;

  @override
  Future<void> loadModel(String modelPath) async {
    if (_isLoaded) {
      _logger.debug(_tag, 'Model already loaded');
      return;
    }

    try {
      _logger.info(_tag, 'Loading emotion model from: $modelPath');

      _interpreter = await Interpreter.fromAsset(
        modelPath,
        options: InterpreterOptions()..threads = 2,
      );

      _isLoaded = true;

      // Determine actual output class count from the model.
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      if (outputTensor.shape.length >= 2) {
        _numClasses = outputTensor.shape.last;
      }
      _logger.info(
        _tag,
        'Model loaded. Input: ${inputTensor.shape}, '
            'Output: ${outputTensor.shape}, '
            'classes: $_numClasses',
      );
    } on Exception catch (e, st) {
      _isLoaded = false;
      _interpreter = null;
      _logger.error(_tag, 'Failed to load emotion model: $e', st);
      throw ModelLoadException(
        message: 'Emotion model load failed: $e',
        stackTrace: st,
      );
    }
  }

  @override
  Future<EmotionResult> analyzeEmotion(FaceCrop faceCrop) async {
    if (!_isLoaded || _interpreter == null) {
      _logger.warning(_tag, 'analyzeEmotion called without loaded model');
      return const EmotionResult.unknown();
    }

    final stopwatch = Stopwatch()..start();

    try {
      // Prepare input tensor [1, 48, 48, 1].
      final input = _prepareInput(faceCrop);

      // Prepare output buffer [1, numClasses].
      final output = List.generate(
        1,
        (_) => List<double>.filled(_numClasses, 0),
      );

      // Run inference.
      _interpreter!.run(input, output);

      stopwatch.stop();

      final raw = RawEmotionData(
        outputScores: output[0],
        inferenceTimeMs: stopwatch.elapsedMilliseconds,
      );

      _logger.debug(
        _tag,
        'Inference: ${stopwatch.elapsedMilliseconds}ms, '
            'scores: ${output[0].map((s) => s.toStringAsFixed(2)).join(", ")}',
      );

      return ResultMapper.fromRawEmotion(raw);
    } on Exception catch (e, st) {
      stopwatch.stop();
      _logger.warning(_tag, 'Emotion inference failed: $e');
      throw InferenceException(
        message: 'Emotion analysis error: $e',
        stackTrace: st,
      );
    }
  }

  /// Prepares the input tensor from a [FaceCrop].
  ///
  /// Expects the crop to already be `_inputSize` x `_inputSize` grayscale
  /// normalised as Float32 (done by `CameraImageMapper.extractFaceCrop`).
  ///
  /// Reshapes to [1, 48, 48, 1] for the model.
  List<List<List<List<double>>>> _prepareInput(FaceCrop faceCrop) {
    final floats = faceCrop.bytes.buffer.asFloat32List();

    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final idx = y * _inputSize + x;
            return idx < floats.length ? floats[idx] : 0.0;
          },
        ),
      ),
    );

    // Reshape to [1, 48, 48, 1] — add channel dimension.
    return List.generate(
      1,
      (b) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) => [input[b][y][x]],
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
    _logger.info(_tag, 'TFLite emotion engine disposed');
  }
}
