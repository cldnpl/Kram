import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../data/camera_models.dart';
import '../providers/camera_provider.dart';
import '../widgets/camera_preview.dart';
import '../widgets/solution_panel.dart';
import 'calculator_page.dart';
import 'camera_history_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraProvider _provider;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _provider = CameraProvider();
    _provider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _provider.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white),
          ),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: _isFlashOn ? Colors.yellow : Colors.white,
              ),
            ),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, color: Colors.white),
            ),
            onPressed: _showHistory,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          _buildCameraPreview(),

          // Focus Frame (when idle)
          if (_provider.state == CameraState.idle) _buildFocusFrame(),

          // Scanning overlay
          if (_provider.state == CameraState.scanning) _buildScanningOverlay(),

          // Processing overlay
          if (_provider.state == CameraState.processing)
            const ProcessingOverlay(),

          // Error overlay
          if (_provider.state == CameraState.error) _buildErrorOverlay(),

          // Solution panel
          if (_provider.state == CameraState.success && _provider.solution != null)
            SolutionPanel(
              response: _provider.solution!,
              visibleSteps: _provider.visibleSteps,
              onClose: _provider.reset,
            ),

          // Bottom controls
          if (_provider.state != CameraState.success)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomControls(),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_provider.isCameraReady) {
      return Container(
        color: Colors.black,
        child: Center(
          child: _provider.errorMessage != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _provider.errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : const CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return CameraPreviewWidget(controller: _provider.cameraController!);
  }

  Widget _buildFocusFrame() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        const focusWidth = 280.0;
        const focusHeight = 200.0;
        const radius = 16.0;
        final focusRect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: focusWidth,
          height: focusHeight,
        );

        return Stack(
          children: [
            // Dark overlay with transparent cutout
            ClipPath(
              clipper: _InvertedRRectClipper(focusRect, radius),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
            // Focus frame border
            Center(
              child: Container(
                width: focusWidth,
                height: focusHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScanningOverlay() {
    return Center(
      child: Container(
        width: 280,
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 3),
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withOpacity(0.3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: const ScanningLineWidget(),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _provider.errorMessage ?? AppLocale.tr('generic_error'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _provider.reset,
              child: Text(AppLocale.tr('try_again')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Uses remaining badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _provider.hasUnlimitedAccess
                        ? AppLocale.tr('camera_unlimited')
                        : AppLocale.trFormat('camera_uses_remaining_format', [_provider.usesRemaining, _provider.dailyLimit]),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Capture button row with calculator
            if (_provider.state == CameraState.idle)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Calculator button
                  GestureDetector(
                    onTap: _openCalculator,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calculate, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Capture button
                  GestureDetector(
                    onTap: (_provider.hasUnlimitedAccess || _provider.usesRemaining > 0) ? _provider.capture : null,
                    child: Opacity(
                      opacity: (_provider.hasUnlimitedAccess || _provider.usesRemaining > 0) ? 1 : 0.5,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Spacer to balance the row
                  const SizedBox(width: 56, height: 56),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (_provider.cameraController == null) return;
    try {
      if (_isFlashOn) {
        await _provider.cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _provider.cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Flash toggle failed: $e');
    }
  }

  void _openCalculator() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CalculatorPage(provider: _provider),
      ),
    );
  }

  Future<void> _showHistory() async {
    await _provider.fetchHistory();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraHistoryPage(history: _provider.history),
        ),
      );
    }
  }
}

class _InvertedRRectClipper extends CustomClipper<Path> {
  final Rect rect;
  final double radius;

  _InvertedRRectClipper(this.rect, this.radius);

  @override
  Path getClip(Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)))
      ..fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(covariant _InvertedRRectClipper oldClipper) {
    return oldClipper.rect != rect || oldClipper.radius != radius;
  }
}
