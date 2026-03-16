import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../data/camera_api.dart';
import '../../data/camera_models.dart';

class CameraProvider extends ChangeNotifier {
  CameraProvider() {
    _api = CameraApi();
    _initCamera();
  }

  late final CameraApi _api;
  CameraController? _cameraController;
  CameraState _state = CameraState.idle;
  SolveResponse? _solution;
  String? _errorMessage;
  int _usesRemaining = 5;
  int _dailyLimit = 5;
  List<HistoryItem> _history = [];
  Set<int> _visibleSteps = {};

  // Getters
  CameraController? get cameraController => _cameraController;
  CameraState get state => _state;
  SolveResponse? get solution => _solution;
  String? get errorMessage => _errorMessage;
  int get usesRemaining => _usesRemaining;
  int get dailyLimit => _dailyLimit;
  List<HistoryItem> get history => _history;
  Set<int> get visibleSteps => _visibleSteps;
  bool get isCameraReady => _cameraController?.value.isInitialized ?? false;
  bool get hasUnlimitedAccess => _dailyLimit < 0 || _usesRemaining < 0;

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _errorMessage = 'No camera available';
        notifyListeners();
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      notifyListeners();

      // Fetch initial status
      await fetchStatus();
    } catch (e) {
      _errorMessage = 'Failed to initialize camera: $e';
      notifyListeners();
    }
  }

  Future<void> fetchStatus() async {
    try {
      final status = await _api.getStatus();
      _usesRemaining = status.remaining;
      _dailyLimit = status.dailyLimit;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch status: $e');
    }
  }

  Future<void> capture() async {
    if (!hasUnlimitedAccess && _usesRemaining <= 0) {
      _state = CameraState.error;
      _errorMessage = 'Daily limit reached. Come back tomorrow!';
      notifyListeners();
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _state = CameraState.error;
      _errorMessage = 'Camera not ready';
      notifyListeners();
      return;
    }

    try {
      _state = CameraState.scanning;
      notifyListeners();

      // Small delay to show scanning animation
      await Future.delayed(const Duration(milliseconds: 500));

      // Capture image
      final XFile imageFile = await _cameraController!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      _state = CameraState.processing;
      notifyListeners();

      // Send to API
      final response = await _api.solve(base64Image, 'image/jpeg');

      _solution = response;
      if (response.usesRemainingToday < 0) {
        _dailyLimit = -1;
        _usesRemaining = -1;
      } else {
        _usesRemaining = response.usesRemainingToday;
      }
      _state = CameraState.success;
      notifyListeners();

      // Animate steps appearing
      await _animateSteps(response.steps.length);
    } catch (e) {
      _state = CameraState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> solveFromText(String problemText) async {
    if (!hasUnlimitedAccess && _usesRemaining <= 0) {
      _state = CameraState.error;
      _errorMessage = 'Daily limit reached. Come back tomorrow!';
      notifyListeners();
      return;
    }

    try {
      _state = CameraState.processing;
      notifyListeners();

      final response = await _api.solveText(problemText);

      _solution = response;
      if (response.usesRemainingToday < 0) {
        _dailyLimit = -1;
        _usesRemaining = -1;
      } else {
        _usesRemaining = response.usesRemainingToday;
      }
      _state = CameraState.success;
      notifyListeners();

      await _animateSteps(response.steps.length);
    } catch (e) {
      _state = CameraState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> _animateSteps(int count) async {
    _visibleSteps = {};
    notifyListeners();

    for (int i = 0; i < count; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      _visibleSteps = {..._visibleSteps, i};
      notifyListeners();
    }
  }

  void reset() {
    _state = CameraState.idle;
    _solution = null;
    _errorMessage = null;
    _visibleSteps = {};
    notifyListeners();
  }

  Future<void> fetchHistory() async {
    try {
      _history = await _api.getHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch history: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
