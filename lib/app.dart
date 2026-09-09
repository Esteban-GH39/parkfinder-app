import 'package:flutter/material.dart';

import 'common/theme.dart';
import 'features/users/registro_cliente_screen.dart';

/// Widget raíz de la app.
///
/// Por ahora abre directamente en el registro de cliente (HU-01). Cuando exista
/// el login (HU-02) y el control de acceso por rol (HU-27), aquí va el router
/// que decide la pantalla inicial según la sesión.
class ParkfinderApp extends StatelessWidget {
  const ParkfinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkFinder',
      debugShowCheckedModeBanner: false,
      theme: parkfinderTheme,
      home: const RegistroClienteScreen(),
    );
  }
}
