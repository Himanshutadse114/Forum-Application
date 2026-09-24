import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // URL to a premium bell/chime sound effect (Adafruit free asset)
  static const String bellSoundUrl =
      'https://raw.githubusercontent.com/adafruit/Adafruit_Learning_System_Guides/master/Playing_Sounds_and_Using_Buttons_with_Raspberry_Pi/temple-bell.mp3';

  Future<void> init() async {
    // 1. Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Request notification permissions for Android 13+
    final androidImplementation =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  // Ring the bell (play sound and vibrate)
  Future<void> ringBell() async {
    try {
      // Vibrate the device
      HapticFeedback.vibrate();
      
      // Play crisp bell sound from Mixkit chime URL
      await _audioPlayer.play(UrlSource(bellSoundUrl));
    } catch (e) {
      print('NotificationHelper: Error playing bell sound: $e');
    }
  }

  // Show a local notification banner on the device
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'cybershield_channel_id',
      'CyberShield Alerts',
      channelDescription: 'Notifications for new cyber security news and advisories',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _localNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );

    // Ring the bell in-app
    await ringBell();
  }
}
