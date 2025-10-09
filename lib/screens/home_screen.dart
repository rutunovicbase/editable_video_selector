import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Home Screen - No BLoC access here
/// This demonstrates that BLoC is NOT available globally
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Home Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'This screen does NOT have access to any BLoC.\nBLoCs are only available in Parent screen and its children.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => context.go('/parent'),
              child: const Text('Go to Parent Screen (with BLoC)'),
            ),
          ],
        ),
      ),
    );
  }
}
