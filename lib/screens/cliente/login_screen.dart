import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/sesion_service.dart';
import 'buscar_screen.dart';
import 'registro_screen.dart';

/// HU-02: inicio de sesión (cliente o administrador, según el rol del usuario).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correoCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  final _authService = AuthService();

  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    final correo = _correoCtrl.text.trim();
    final contrasena = _contrasenaCtrl.text;
    if (correo.isEmpty || contrasena.isEmpty) {
      setState(() => _error = 'Ingresa tu correo y tu contraseña');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    final resultado = await _authService.iniciarSesion(correo, contrasena);
    if (!mounted) return;
    if (resultado['success'] == true) {
      final datos = resultado['data'] as Map<String, dynamic>;
      final sesion = SesionService.instancia;
      sesion.iniciar(
        nombre: '${datos['nombre'] ?? ''}',
        correo: '${datos['correo'] ?? correo}',
        rol: '${datos['rol'] ?? 'CLIENTE'}',
      );
      final Widget destino = sesion.esAdmin
          ? const _PanelAdminPendiente()
          : const BuscarScreen();
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => destino));
    } else {
      setState(() {
        _error = '${resultado['error']}';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              key: const Key('campoCorreo'),
              controller: _correoCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            TextField(
              key: const Key('campoContrasena'),
              controller: _contrasenaCtrl,
              obscureText: true,
              onSubmitted: (_) => _iniciarSesion(),
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
              key: const Key('botonIniciarSesion'),
              onPressed: _cargando ? null : _iniciarSesion,
              child: _cargando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Iniciar sesión'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const RegistroScreen())),
              child: const Text('¿No tienes cuenta? Regístrate'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marcador de posición hasta que existan las pantallas de administración.
class _PanelAdminPendiente extends StatelessWidget {
  const _PanelAdminPendiente();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de administrador')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Sesión de administrador iniciada.\n'
            'Aquí irán las pantallas de administración.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
