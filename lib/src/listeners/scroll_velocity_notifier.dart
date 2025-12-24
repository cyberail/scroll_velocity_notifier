import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:scroll_velocity_notifier/src/types/scroll_stream_notification.dart';

import '../types/velocity_listener_callback.dart';

/// A widget that intercepts scroll notifications and computes
/// an estimated scroll velocity, then forwards both the original
/// notification and the computed velocity to a callback.
///
/// This widget is implemented as a [ProxyWidget] so it can sit
/// transparently in the widget tree without affecting layout,
/// while still participating in the notification system.
///
/// Typical use cases:
/// - Showing / hiding UI based on scroll speed
/// - Applying inertia-based effects
/// - Advanced scroll-aware animations
class ScrollVelocityNotifier extends ProxyWidget {
  const ScrollVelocityNotifier({
    super.key,
    required super.child,
    this.onNotification,
    this.includeOversScroll = false,
    this.controller,
  });

  /// Callback invoked for each received [ScrollNotification].
  ///
  /// The callback receives:
  /// - the original [ScrollNotification]
  /// - the calculated scroll velocity (pixels per second)
  ///
  /// Returning `true` will stop the notification from bubbling
  /// further up the tree.
  final VelocityListenerCallback? onNotification;

  /// Optional [StreamController] used to emit scroll velocity updates.
  ///
  /// When provided, this widget will add [ScrollStreamNotification] events
  /// to the controller whenever a [ScrollUpdateNotification] is received.
  ///
  /// Each emitted event contains:
  /// - the original [ScrollNotification]
  /// - the calculated scroll velocity (pixels per second)
  ///
  /// ### Ownership & Lifecycle
  /// - The controller is **NOT disposed** by this widget.
  /// - The caller is responsible for creating and disposing the controller.
  /// - This allows the controller to be shared across widgets or listened to
  ///   by multiple consumers.
  ///
  /// The controller should be configured as a broadcast stream if multiple
  /// listeners are expected:
  ///
  /// ```dart
  /// final controller = StreamController<ScrollStreamNotification>.broadcast();
  /// ```
  ///
  /// If no controller is provided, no stream events are emitted.
  final StreamController<ScrollStreamNotification>? controller;

  /// Whether scroll velocity should be calculated during overscroll.
  ///
  /// Overscroll happens when using physics like [BouncingScrollPhysics].
  ///
  /// If set to `false`:
  /// - Velocity will be reported as `0` while overscrolling.
  ///
  /// If set to `true`:
  /// - Velocity will continue to be calculated beyond scroll bounds.
  final bool includeOversScroll;

  @override
  Element createElement() {
    return _ScrollVelocityNotifier(this);
  }
}

/// Element implementation for [ScrollVelocityNotifier].
///
/// This element:
/// - Listens to scroll notifications
/// - Calculates scroll velocity using time deltas
/// - Applies exponential moving average (EMA) smoothing
///
/// Implemented as a [ProxyElement] to avoid interfering with
/// the widget subtree while still intercepting notifications.
class _ScrollVelocityNotifier extends ProxyElement with NotifiableElementMixin {
  _ScrollVelocityNotifier(ScrollVelocityNotifier super.widget);

  /// Stopwatch used to measure time between scroll updates.
  ///
  /// No disposal is required — [Stopwatch] is a pure Dart object.
  final Stopwatch _scrollClock = Stopwatch()..start();

  /// Timestamp of the previous scroll update (microseconds).
  int? _lastUs;

  /// Scroll position of the previous update (pixels).
  double? _lastPixels;

  /// Exponential moving average of the scroll velocity.
  ///
  /// Used to smooth noisy velocity values.
  double _ema = 0;

  /// EMA smoothing factor.
  ///
  /// Lower values = more smoothing
  /// Higher values = more responsiveness
  double alpha = 0.15;

  /// Calculates the current scroll velocity in pixels per second.
  ///
  /// Returns:
  /// - `double` → smoothed velocity
  /// - `0` → overscroll velocity if ignored
  /// - `null` → insufficient data (first event)
  double? calculateVelocity(ScrollUpdateNotification updateEvent) {
    final metrics = updateEvent.metrics;

    if (!(widget as ScrollVelocityNotifier).includeOversScroll && metrics.pixels < metrics.minScrollExtent ||
        metrics.pixels > metrics.maxScrollExtent) {
      return 0;
    }

    final nowUs = _scrollClock.elapsedMicroseconds;
    final pixels = updateEvent.metrics.pixels;

    if (_lastUs != null && _lastPixels != null) {
      final delta = (nowUs - _lastUs!) / 1e6;
      if (delta > 0) {
        final raw = (pixels - _lastPixels!) / delta;

        _ema = (_ema == 0) ? raw : (_ema * (1 - alpha) + raw * alpha);

        _lastUs = nowUs;
        _lastPixels = pixels;
        return _ema;
      }
    }

    _lastUs = nowUs;
    _lastPixels = pixels;
    return null;
  }

  /// Receives notifications from the widget subtree.
  ///
  /// When a [ScrollNotification] is received:
  /// - Calculates velocity (if applicable)
  /// - Forwards both notification and velocity to the callback
  @override
  bool onNotification(Notification notification) {
    final ScrollVelocityNotifier listener = widget as ScrollVelocityNotifier;
    if (listener.onNotification != null && notification is ScrollNotification) {
      double velocity = 0;

      if (notification is ScrollUpdateNotification) {
        velocity = calculateVelocity(notification) ?? 0;
      }

      if (listener.controller != null) {
        listener.controller?.add(ScrollStreamNotification(notification: notification, velocity: velocity));
      }

      return listener.onNotification!(notification, velocity);
    }
    return false;
  }

  /// Required override for [ProxyElement].
  ///
  /// Notification propagation does not require client updates.
  @override
  void notifyClients(covariant ProxyWidget oldWidget) {
    // No-op
  }

  /// Cleanup hook for the element lifecycle.
  ///
  /// This is the equivalent of `dispose()` for elements.
  ///
  /// ⚠️ Only objects owned by this element should be cleaned up here.
  /// The provided [ScrollController] is disposed here, which implies
  /// ownership by this widget.
  @override
  void unmount() {
    super.unmount();
  }
}
