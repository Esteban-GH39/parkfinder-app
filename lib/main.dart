import 'package:flutter/material.dart';

import 'screens/admin/lista_parqueaderos_screen.dart';
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
      // HU-19: mientras no exista el login (HU-17) que lleve al administrador
      // a su panel, la lista de parqueaderos se abre por ruta:
      //   flutter run --route=/admin/parqueaderos
      routes: {
        '/admin/parqueaderos': (_) => const ListaParqueaderosScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
