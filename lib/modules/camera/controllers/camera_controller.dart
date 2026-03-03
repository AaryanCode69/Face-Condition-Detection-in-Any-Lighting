import 'dart:async';
import 'dart:ui';

import 'package:face_mood_light_detector/core/error/error_handler.dart';
import 'package:face_mood_light_detector/core/error/failures.dart';
import 'package:face_mood_light_detector/core/logger/app_logger.dart';
import 'package:face_mood_light_detector/domain/enums/camera_state.dart';
import 'package:face_mood_light_detector/services/camera_service.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class AppCameraController extends GetxController {
  AppCameraController({
    required CameraService cameraService,
    required AppLogger logger,
    required ErrorHandler errorHandler,
  })  : _cameraService = cameraService,
        _logger = logger,
        _errorHandler = errorHandler;

  final CameraService _cameraService;
  final AppLogger _logger;
  final ErrorHandler _errorHandler;
  static const String _tag = 'CameraCtrl';

  // -- Reactive state --

  final cameraState = CameraState.idle.obs;
  final isFrontCamera = true.obs;
  final isPermissionGranted = false.obs;
  final previewSize = Rxn<Size>();

  CameraService get cameraService => _cameraService;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initializeCamera());
  }

  Future<void> _initializeCamera() async {
    cameraState.value = CameraState.initializing;

    final granted = await _cameraService.requestPermission();
    isPermissionGranted.value = granted;

    if (!granted) {
      cameraState.value = CameraState.error;
      _errorHandler.handleCameraError(const CameraPermissionFailure());
      return;
    }

    try {
      await _cameraService.initialize(
        useFrontCamera: isFrontCamera.value,
      );
      previewSize.value = _cameraService.previewSize;

      await _cameraService.startStreaming();
      cameraState.value = CameraState.ready;
      _logger.info(
        _tag,
        'Camera ready, preview: ${previewSize.value}',
      );
    } on Exception catch (e, st) {
      cameraState.value = CameraState.error;
      _errorHandler.handleCameraError(
        CameraInitFailure(message: '$e', stackTrace: st),
      );
    }
  }

  Future<void> toggleCamera() async {
    if (cameraState.value != CameraState.ready) return;

    cameraState.value = CameraState.initializing;
    try {
      await _cameraService.switchCamera();
      isFrontCamera.value = _cameraService.isFrontCamera;
      previewSize.value = _cameraService.previewSize;
      cameraState.value = CameraState.ready;
      _logger.info(
        _tag,
        'Switched to ${isFrontCamera.value ? "front" : "back"} camera',
      );
    } on Exception catch (e, st) {
      cameraState.value = CameraState.error;
      _errorHandler.handleCameraError(
        CameraInitFailure(
          message: 'Camera switch failed: $e',
          stackTrace: st,
        ),
      );
    }
  }

  Future<void> retryPermission() async {
    final granted = await _cameraService.checkPermission();
    if (granted) {
      isPermissionGranted.value = true;
      await _initializeCamera();
    } else {
      await openAppSettings();
    }
  }

  @override
  void onClose() {
    unawaited(_cameraService.dispose());
    super.onClose();
  }
}
