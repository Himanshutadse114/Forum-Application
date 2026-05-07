import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cybershield_forum/core/hive_box.dart';
import 'package:cybershield_forum/core/router.dart';
import 'package:cybershield_forum/core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive storage for persistent JWT tokens and gamification user stats
  await HiveBoxHelper.init();

  runApp(
    const ProviderScope(
      child: CyberShieldApp(),
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
