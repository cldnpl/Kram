import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solve Math'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 300,
              height: 300,
              color: Colors.grey.shade800,
              child: const Icon(Icons.camera_alt, size: 64),
            ),
            const SizedBox(height: 24),
            Text('2 uses left today', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.camera),
              label: const Text('Capture'),
            ),
          ],
        ),
      ),
    );
  }
}
