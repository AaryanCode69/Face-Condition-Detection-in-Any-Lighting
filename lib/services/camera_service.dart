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

/// Manages camera lifecycle, permissions, and frame streaming.
///
/// Implements [WidgetsBindingObserver] to automatically pause/resume the
/// camera when the app goes to/from the background, preventing resource
/// leaks (Architecture §6 — Memory Safety Rule #3).
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

  /// Platform-agnostic camera frame stream.
  /// Multiple listeners supported (broadcast).
  Stream<CameraFrame> get frameStream => _frameStreamController.stream;

  bool get isStreaming => _isStreaming;
  bool get isInitialized =>
      _cameraController?.value.isInitialized ?? false;
  bool get isFrontCamera => _isFrontCamera;

  /// Exposes the underlying camera controller for the preview widget.
  cam.CameraController? get controller => _cameraController;

  /// Camera sensor orientation in degrees (0, 90, 180, 270).
  int get sensorOrientation =>
      _cameraController?.description.sensorOrientation ?? 0;

  /// Preview size reported by the camera (landscape dimensions).
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

  /// Requests camera permission via the permission_handler plugin.
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

  /// Checks camera permission without requesting.
  Future<bool> checkPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes the camera hardware.
  ///
  /// Must call [requestPermission] first if permission has not been granted.
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
    // Dispose previous controller if any.
    await _stopStreaming();
    await _cameraController?.dispose();

    _cameraController = cam.CameraController(
      camera,
      cam.ResolutionPreset.medium, // 720p — balance quality/performance
      enableAudio: false,
      imageFormatGroup: cam.ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
  }

  // ---------------------------------------------------------------------------
  // Streaming
  // ---------------------------------------------------------------------------

  /// Starts the camera image stream and enables wakelock.
  ///
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

  void _onImageAvailable(cam.CameraImage image) {
    if (_isDisposed || _frameStreamController.isClosed) return;

    // Record frame for FPS tracking.
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

  /// Stops the image stream without disposing the camera.
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

  /// Switches between front and back camera.
  ///
  /// Stops streaming, re-initializes with the other lens, and resumes
  /// streaming if it was previously active.
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

  /// Sets exposure compensation in EV stops.
  ///
  /// Clamped to the device's supported range.
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

  /// Pauses the camera (e.g., when app goes to background).
  Future<void> pause() async {
    _logger.debug(_tag, 'Pausing camera');
    await _stopStreaming();
  }

  /// Resumes the camera (e.g., when app returns to foreground).
  Future<void> resume() async {
    if (_cameraController == null || _isDisposed) return;

    _logger.debug(_tag, 'Resuming camera');
    if (_cameraController!.value.isInitialized) {
      await startStreaming();
    }
  }

  /// Releases all camera resources.
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
