import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  final plugin = FlutterLocalNotificationsPlugin();
  // We try passing settings as named parameter.
  plugin.initialize(settings: null);
}
