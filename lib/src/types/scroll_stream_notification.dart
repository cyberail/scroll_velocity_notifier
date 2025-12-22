import 'package:flutter/widgets.dart';

class ScrollStreamNotification {
  final ScrollNotification notification;
  final double? velocity;

  ScrollStreamNotification({required this.notification, this.velocity});
}
