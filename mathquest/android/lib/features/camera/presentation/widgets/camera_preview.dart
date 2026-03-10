import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../core/l10n/app_locale.dart';

class CameraPreviewWidget extends StatelessWidget {
  const CameraPreviewWidget({
    super.key,
    required this.controller,
  });

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return ClipRRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? 0,
            height: controller.value.previewSize?.width ?? 0,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class ScanningLineWidget extends StatefulWidget {
  const ScanningLineWidget({super.key});

  @override
  State<ScanningLineWidget> createState() => _ScanningLineWidgetState();
}

class _ScanningLineWidgetState extends State<ScanningLineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return FractionallySizedBox(
          alignment: Alignment(0, -1 + _animation.value * 2),
          heightFactor: 0.02,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0),
                  Colors.green.withOpacity(0.8),
                  Colors.green.withOpacity(0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProcessingOverlay extends StatefulWidget {
  const ProcessingOverlay({super.key});

  @override
  State<ProcessingOverlay> createState() => _ProcessingOverlayState();
}

class _ProcessingOverlayState extends State<ProcessingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _controller,
              child: SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  backgroundColor: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocale.tr('solving'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
