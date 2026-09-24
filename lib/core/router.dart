import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cybershield_forum/core/hive_box.dart';
import 'package:cybershield_forum/features/auth/screens/login_screen.dart';
import 'package:cybershield_forum/features/auth/screens/register_screen.dart';
import 'package:cybershield_forum/features/dashboard/screens/dashboard_screen.dart';
import 'package:cybershield_forum/features/forum/screens/forum_list_screen.dart';
import 'package:cybershield_forum/features/forum/screens/post_detail_screen.dart';
import 'package:cybershield_forum/features/forum/screens/create_post_screen.dart';

import 'package:cybershield_forum/features/dashboard/screens/cyber_match_game_screen.dart';
import 'package:cybershield_forum/features/dashboard/screens/firewall_drone_game_screen.dart';
import 'package:cybershield_forum/features/dashboard/screens/shield_maze_game_screen.dart';

import 'package:cybershield_forum/features/admin/screens/super_admin_screen.dart';
import 'package:cybershield_forum/features/admin/screens/admin_analytics_screen.dart';
import 'package:cybershield_forum/features/admin/screens/user_detail_screen.dart';
import 'package:cybershield_forum/features/anti_fraud/screens/sms_scanner_screen.dart';
import 'package:cybershield_forum/features/anti_fraud/screens/eml_scanner_screen.dart';
import 'package:cybershield_forum/features/anti_fraud/screens/link_scanner_screen.dart';
import 'package:cybershield_forum/features/anti_fraud/screens/apk_scanner_screen.dart';
import 'package:cybershield_forum/features/anti_fraud/screens/sentinel_coach_screen.dart';

final GlobalKey<NavigatorState> cyberNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter cyberRouter = GoRouter(
  navigatorKey: cyberNavigatorKey,
  initialLocation: HiveBoxHelper.isLoggedIn() ? '/' : '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/cyber-match',
      builder: (context, state) => const CyberMatchGameScreen(),
    ),
    GoRoute(
      path: '/firewall-drone',
      builder: (context, state) => const FirewallDroneGameScreen(),
    ),
    GoRoute(
      path: '/shield-maze',
      builder: (context, state) => const ShieldMazeGameScreen(),
    ),
    GoRoute(
      path: '/forum/:categoryId/:categoryName',
      builder: (context, state) {
        final categoryId = int.parse(state.pathParameters['categoryId']!);
        final categoryName = state.pathParameters['categoryName']!;
        return ForumListScreen(categoryId: categoryId, categoryName: categoryName);
      },
    ),
    GoRoute(
      path: '/post-detail/:postId',
      builder: (context, state) {
        final postId = int.parse(state.pathParameters['postId']!);
        return PostDetailScreen(postId: postId);
      },
    ),
    GoRoute(
      path: '/create-post/:categoryId',
      builder: (context, state) {
        final categoryId = int.parse(state.pathParameters['categoryId']!);
        return CreatePostScreen(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: '/super-admin',
      builder: (context, state) => const SuperAdminScreen(),
    ),
    GoRoute(
      path: '/admin-analytics',
      builder: (context, state) => const AdminAnalyticsScreen(),
    ),
    GoRoute(
      path: '/user-detail/:userId',
      builder: (context, state) {
        final userId = int.parse(state.pathParameters['userId']!);
        return UserDetailScreen(userId: userId);
      },
    ),
    GoRoute(
      path: '/sms-scanner',
      builder: (context, state) => const SmsScannerScreen(),
    ),
    GoRoute(
      path: '/eml-scanner',
      builder: (context, state) => const EmlScannerScreen(),
    ),
    GoRoute(
      path: '/link-scanner',
      builder: (context, state) {
        final url = state.uri.queryParameters['url'];
        return LinkScannerScreen(initialUrl: url);
      },
    ),
    GoRoute(
      path: '/apk-scanner',
      builder: (context, state) {
        final tabStr = state.uri.queryParameters['tab'];
        final initialTab = tabStr != null ? int.tryParse(tabStr) ?? 0 : 0;
        return ApkScannerScreen(initialTab: initialTab);
      },
    ),
    GoRoute(
      path: '/sentinel-coach',
      builder: (context, state) => const SentinelCoachScreen(),
    ),
  ],
);
