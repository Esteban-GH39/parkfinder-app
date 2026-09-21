import 'package:flutter/material.dart';

import 'screens/cliente/registro_screen.dart';

void main() {
  runApp(const ParkFinderApp());
}

class ParkFinderApp extends StatelessWidget {
  const ParkFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkFinder',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RegistroScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
