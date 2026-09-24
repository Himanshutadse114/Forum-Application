import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cybershield_forum/core/hive_box.dart';
import 'package:cybershield_forum/core/router.dart';
import 'package:cybershield_forum/core/theme.dart';
import 'package:cybershield_forum/core/security_service.dart';
import 'package:cybershield_forum/core/global_channel_handler.dart';
import 'package:cybershield_forum/core/notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize freeRASP application shielding
  await SecurityService.init();
  
  // Initialize Hive storage for persistent JWT tokens and gamification user stats
  await HiveBoxHelper.init();

  // Initialize global MethodChannel handler for installations and link shares
  GlobalChannelHandler.init();

  // Initialize notifications
  await NotificationHelper().init();

  runApp(
    ProviderScope(
      child: SecurityService.securityWrapper(const CyberShieldApp()),
    ),
  );
}

class CyberShieldApp extends StatelessWidget {
  const CyberShieldApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'CyberShield Forum',
      theme: CyberTheme.darkTheme,
      routerConfig: cyberRouter,
    );
  }
}
