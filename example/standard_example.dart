import 'package:flutter/material.dart';
import 'package:scroll_velocity_notifier/scroll_velocity_notifier.dart';

void main() {
  runApp(const BasicExampleApp());
}

class BasicExampleApp extends StatelessWidget {
  const BasicExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BasicExampleScreen(),
    );
  }
}

class BasicExampleScreen extends StatelessWidget {
  const BasicExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scroll Velocity – Basic'),
      ),
      body: ScrollVelocityProvider(
        onNotification: (notification, velocity) {
          debugPrint('Scroll velocity: $velocity px/s');
          return false; // allow notification to bubble up
        },
        child: ListView.builder(
          itemCount: 50,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text('Item $index'),
            );
          },
        ),
      ),
    );
  }
}
