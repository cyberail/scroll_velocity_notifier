import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scroll_velocity_notifier/scroll_velocity_notifier.dart';

void main() {
  runApp(const StreamControllerExampleApp());
}

class StreamControllerExampleApp extends StatelessWidget {
  const StreamControllerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: StreamControllerExampleScreen(),
    );
  }
}

class StreamControllerExampleScreen extends StatefulWidget {
  const StreamControllerExampleScreen({super.key});

  @override
  State<StreamControllerExampleScreen> createState() =>
      _StreamControllerExampleScreenState();
}

class _StreamControllerExampleScreenState
    extends State<StreamControllerExampleScreen> {
  late final StreamController<ScrollStreamNotification> _controller;
  StreamSubscription<ScrollStreamNotification>? _subscription;

  @override
  void initState() {
    super.initState();

    _controller = StreamController<ScrollStreamNotification>.broadcast();

    _subscription = _controller.stream.listen((event) {
      debugPrint(
        'Velocity from stream: ${event.velocity} px/s',
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scroll Velocity – StreamController'),
      ),
      body: ScrollVelocityProvider(
        controller: _controller,
        includeOversScroll: true,
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
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
