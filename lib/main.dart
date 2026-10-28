import 'package:flutter/material.dart';
import 'package:parkfinder_app/screens/admin/registrar_parqueadero_screen.dart';
import 'package:parkfinder_app/screens/admin/id_admin_temporal_screen.dart';

import 'screens/cliente/registro_screen.dart';

void main() {
  runApp(const ParkFinderApp());
}

class ParkFinderApp extends StatelessWidget {
  const ParkFinderApp({super.key});

  //HU-REGISTRO PARQUEADERO
  /*@override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkFinder',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RegistroParqueaderoScreen(),
      debugShowCheckedModeBanner: false,
    );
  }*/


  //HU-LISTAR PARQUEADERO CON ID ADMIN
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ParkFinder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const IngresarAdminScreen(),
    );
  }
}
