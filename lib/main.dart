import 'package:flutter/material.dart';

import 'screens/cliente/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ParkFinderApp());
}

class ParkFinderApp extends StatelessWidget {
  const ParkFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkFinder',
      theme: AppTheme.claro,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
