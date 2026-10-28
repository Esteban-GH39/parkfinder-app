import 'package:flutter/material.dart';

import '../../models/cliente.dart';
import '../../services/api_service.dart';
import '../../theme/widgets_comunes.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  final _apiService = ApiService();
  bool _cargando = false;
  String? _errorMensaje;

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });

    final cliente = Cliente(
      nombre: _nombreCtrl.text,
      correo: _correoCtrl.text,
      contrasena: _contrasenaCtrl.text,
    );
    final resultado = await _apiService.registrarCliente(cliente);

    setState(() => _cargando = false);
    if (resultado['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada correctamente')),
        );
        Navigator.of(context).pop(); // vuelve al inicio de sesión
      }
    } else {
      setState(() => _errorMensaje = resultado['error']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const _BotonAtras(),
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              TarjetaBlanca(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crea tu cuenta para buscar, reservar y pagar tu parqueadero',
                        style: TextStyle(fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Nombre',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _correoCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Correo',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Correo inválido'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contrasenaCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 8) {
                            return 'Mínimo 8 caracteres';
                          }
                          if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$')
                              .hasMatch(v)) {
                            return 'Debe incluir letra y número';
                          }
                          return null;
                        },
                      ),
                      if (_errorMensaje != null) ...[
                        const SizedBox(height: 16),
                        AvisoError(texto: _errorMensaje!),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _cargando ? null : _registrar,
                        child: _cargando
                            ? const CargandoEnBoton()
                            : const Text('Registrarme'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('¿Ya tienes cuenta? Inicia sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonAtras extends StatelessWidget {
  const _BotonAtras();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
    child: Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).maybePop(),
        child: const Icon(Icons.chevron_left, size: 26),
      ),
    ),
  );
}
