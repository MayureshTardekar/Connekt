import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Your actual screens
import '../../screens/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/main_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const MainScreen(),
    ),
  ],
);
