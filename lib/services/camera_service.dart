import 'dart:async';

import 'package:camera/camera.dart' as cam;
import 'package:face_mood_light_detector/core/error/exceptions.dart';
import 'package:face_mood_light_detector/core/logger/app_logger.dart';
import 'package:face_mood_light_detector/core/performance/frame_rate_monitor.dart';
import 'package:face_mood_light_detector/data/mappers/camera_image_mapper.dart';
import 'package:face_mood_light_detector/domain/entities/face_detection_result.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class CameraService with WidgetsBindingObserver {
  CameraService({
    required AppLogger logger,
    required FrameRateMonitor frameRateMonitor,
  })  : _logger = logger,
        _frameRateMonitor = frameRateMonitor;

  final AppLogger _logger;
  final FrameRateMonitor _frameRateMonitor;
  static const String _tag = 'Camera';

  cam.CameraController? _cameraController;
  List<cam.CameraDescription>? _cameras;
  bool _isStreaming = false;
  bool _isFrontCamera = true;
  bool _isDisposed = false;

  final StreamController<CameraFrame> _frameStreamController =
      StreamController<CameraFrame>.broadcast();

  Stream<CameraFrame> get frameStream => _frameStreamController.stream;

  bool get isStreaming => _isStreaming;
  bool get isInitialized =>
      _cameraController?.value.isInitialized ?? false;
  bool get isFrontCamera => _isFrontCamera;

  cam.CameraController? get controller => _cameraController;

  /// Camera sensor orientation in degrees (0, 90, 180, 270).
  int get sensorOrientation =>
      _cameraController?.description.sensorOrientation ?? 0;

  Size? get previewSize {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return null;
    }
    return _cameraController!.value.previewSize;
  }

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  Future<bool> requestPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _logger.info(_tag, 'Camera permission granted');
      return true;
    }
    if (status.isPermanentlyDenied) {
      _logger.warning(_tag, 'Camera permission permanently denied');
    } else {
      _logger.warning(_tag, 'Camera permission denied: $status');
    }
    return false;
  }

  Future<bool> checkPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Throws [CameraUnavailableException] if no cameras are found.
  /// Throws [CameraInitException] on initialization failure.
  Future<void> initialize({bool useFrontCamera = true}) async {
    _isFrontCamera = useFrontCamera;
    _logger.info(
      _tag,
      'Initializing camera (front: $useFrontCamera)',
    );

    try {
      _cameras = await cam.availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw const CameraUnavailableException(
          message: 'No cameras available on this device',
        );
      }

      final targetDirection = useFrontCamera
          ? cam.CameraLensDirection.front
          : cam.CameraLensDirection.back;

      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == targetDirection,
        orElse: () => _cameras!.first,
      );

      await _initController(camera);
      WidgetsBinding.instance.addObserver(this);
      _logger.info(_tag, 'Camera initialized successfully');
    } on CameraUnavailableException {
      rethrow;
    } catch (e, st) {
      _logger.error(_tag, 'Camera init failed: $e', st);
      throw CameraInitException(
        message: 'Camera initialization failed: $e',
        stackTrace: st,
      );
    }
  }

  Future<void> _initController(cam.CameraDescription camera) async {
    await _stopStreaming();
    await _cameraController?.dispose();

    _cameraController = cam.CameraController(
      camera,
      cam.ResolutionPreset.medium, // 720p — balance quality/performance
      enableAudio: false,
      imageFormatGroup: cam.ImageFormatGroup.nv21,
    );

    await _cameraController!.initialize();
  }

  // ---------------------------------------------------------------------------
  // Streaming
  // ---------------------------------------------------------------------------

  /// Throws [CameraInitException] if the camera is not initialized.
  Future<void> startStreaming() async {
    if (_isStreaming) return;
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      throw const CameraInitException(
        message: 'Camera not initialized. Call initialize() first.',
      );
    }

    _logger.debug(_tag, 'Starting image stream');
    await _cameraController!.startImageStream(_onImageAvailable);
    _isStreaming = true;
    await WakelockPlus.enable();
    _logger.info(_tag, 'Image stream started');
  }

  /// When `true`, new camera frames are dropped in `_onImageAvailable`
  /// to prevent the native ImageReader buffer queue from overflowing.
  bool isFrameBusy = false;

  /// Timestamp of the last frame we actually converted and emitted.
  /// Used to enforce a hard rate limit at the camera callback level
  /// BEFORE any byte copying, preventing the native ImageReader
  /// BufferQueue from overflowing (TIMED_OUT crash).
  int _lastEmittedFrameMs = 0;

  /// Minimum interval between emitted frames in milliseconds.
  /// At 12fps this is ~83ms — ensures we never copy more than
  /// 12 frames/sec even if the camera fires callbacks at 30fps.
  static const int _minFrameIntervalMs = 83;

  void _onImageAvailable(cam.CameraImage image) {
    if (_isDisposed || _frameStreamController.isClosed) return;

    // Back-pressure: skip this frame entirely if the pipeline hasn't
    // finished with the previous one. Returning quickly lets the
    // native camera recycle this buffer immediately.
    if (isFrameBusy) return;

    // Hard rate-limit at the camera callback level to prevent native
    // ImageReader BufferQueue overflow. This check runs BEFORE any
    // byte copying so dropped frames return near-instantly.
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastEmittedFrameMs < _minFrameIntervalMs) return;
    _lastEmittedFrameMs = now;

    _frameRateMonitor.recordFrame();

    try {
      final frame = CameraImageMapper.toCameraFrame(
        image,
        sensorOrientation,
      );
      _frameStreamController.add(frame);
    } on Exception catch (e, st) {
      _logger.warning(_tag, 'Frame conversion failed: $e');
      // Skip this frame and continue — do not crash the stream.
      _frameStreamController.addError(
        FrameProcessingException(
          message: 'Frame conversion error: $e',
          stackTrace: st,
        ),
      );
    }
  }

  Future<void> _stopStreaming() async {
    if (!_isStreaming || _cameraController == null) return;

    try {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
    } on Exception catch (e) {
      _logger.warning(_tag, 'Error stopping stream: $e');
    }
    _isStreaming = false;
  }

  // ---------------------------------------------------------------------------
  // Camera controls
  // ---------------------------------------------------------------------------

  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return;

    _isFrontCamera = !_isFrontCamera;
    _logger.info(
      _tag,
      'Switching to ${_isFrontCamera ? "front" : "back"} camera',
    );

    final targetDirection = _isFrontCamera
        ? cam.CameraLensDirection.front
        : cam.CameraLensDirection.back;

    final camera = _cameras!.firstWhere(
      (c) => c.lensDirection == targetDirection,
      orElse: () => _cameras!.first,
    );

    final wasStreaming = _isStreaming;
    await _stopStreaming();
    await _initController(camera);
    if (wasStreaming) {
      await startStreaming();
    }
  }

  /// Sets exposure compensation in EV stops, clamped to device range.
  Future<void> setExposure(double value) async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final minExposure =
          await _cameraController!.getMinExposureOffset();
      final maxExposure =
          await _cameraController!.getMaxExposureOffset();
      final clamped = value.clamp(minExposure, maxExposure);
      await _cameraController!.setExposureOffset(clamped);
      _logger.debug(_tag, 'Exposure set to $clamped EV');
    } on Exception catch (e) {
      _logger.warning(_tag, 'Failed to set exposure: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> pause() async {
    _logger.debug(_tag, 'Pausing camera');
    await _stopStreaming();
  }

  Future<void> resume() async {
    if (_cameraController == null || _isDisposed) return;

    _logger.debug(_tag, 'Resuming camera');
    if (_cameraController!.value.isInitialized) {
      await startStreaming();
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _logger.info(_tag, 'Disposing camera service');

    await _stopStreaming();
    await WakelockPlus.disable();
    WidgetsBinding.instance.removeObserver(this);
    await _cameraController?.dispose();
    _cameraController = null;
    await _frameStreamController.close();
  }

  // ---------------------------------------------------------------------------
  // WidgetsBindingObserver
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(pause());
      case AppLifecycleState.resumed:
        unawaited(resume());
      case AppLifecycleState.hidden:
        break;
    }
  }
}
