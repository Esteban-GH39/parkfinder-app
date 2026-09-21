import 'package:flutter/material.dart';

import '../../models/cliente.dart';
import '../../services/api_service.dart';

import 'buscar_screen.dart';

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
      }
    } else {
      setState(() => _errorMensaje = resultado['error']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _correoCtrl,
                decoration: const InputDecoration(labelText: 'Correo'),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Correo inválido' : null,
              ),
              TextFormField(
                controller: _contrasenaCtrl,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.length < 8) return 'Mínimo 8 caracteres';
                  if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$').hasMatch(v)) {
                    return 'Debe incluir letra y número';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (_errorMensaje != null)
                Text(_errorMensaje!, style: const TextStyle(color: Colors.red)),
              _cargando
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _registrar,
                      child: const Text('Registrarme'),
                    ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BuscarScreen(),
                    ),
                  );
                },
                child: const Text('Ir a Buscar Parqueaderos (Temporal)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
