import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cybershield_forum/core/hive_box.dart';
import 'package:cybershield_forum/features/auth/screens/login_screen.dart';
import 'package:cybershield_forum/features/auth/screens/register_screen.dart';
import 'package:cybershield_forum/features/dashboard/screens/dashboard_screen.dart';
import 'package:cybershield_forum/features/forum/screens/forum_list_screen.dart';
import 'package:cybershield_forum/features/forum/screens/post_detail_screen.dart';
import 'package:cybershield_forum/features/forum/screens/create_post_screen.dart';

final GoRouter cyberRouter = GoRouter(
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
  ],
);
