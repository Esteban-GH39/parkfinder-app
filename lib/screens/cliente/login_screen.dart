import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/sesion_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets_comunes.dart';
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
        id: (datos['id'] as num?)?.toInt(),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const EncabezadoMarca(
                  subtitulo: 'Encuentra y reserva tu parqueadero',
                ),
                const SizedBox(height: 32),
                TarjetaBlanca(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        key: const Key('campoCorreo'),
                        controller: _correoCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Correo',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('campoContrasena'),
                        controller: _contrasenaCtrl,
                        obscureText: true,
                        onSubmitted: (_) => _iniciarSesion(),
                        decoration: const InputDecoration(
                          hintText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        AvisoError(texto: _error!),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('botonIniciarSesion'),
                        onPressed: _cargando ? null : _iniciarSesion,
                        child: _cargando
                            ? const CargandoEnBoton()
                            : const Text('Iniciar sesión'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegistroScreen()),
                  ),
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
              ],
            ),
          ),
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
            style: TextStyle(color: AppColors.textoSuave),
          ),
        ),
      ),
    );
  }
}
