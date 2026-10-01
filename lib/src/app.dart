import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/entry_screens.dart';
import 'screens/home_shell.dart';
import 'theme.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/home', builder: (_, _) => const HomeShell()),
  ],
);

class SduCampusApp extends StatelessWidget {
  const SduCampusApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'SDU Campus',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    routerConfig: _router,
  );
}
