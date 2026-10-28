import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'listar_parqueaderos_screen.dart';

class IngresarAdminScreen extends StatefulWidget {
  const IngresarAdminScreen({super.key});

  @override
  State<IngresarAdminScreen> createState() => _IngresarAdminScreenState();
}

class _IngresarAdminScreenState extends State<IngresarAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idAdminController = TextEditingController();

  @override
  void dispose() {
    _idAdminController.dispose();
    super.dispose();
  }

  void _ingresar() {
    if (_formKey.currentState!.validate()) {
      final int idAdmin = int.parse(_idAdminController.text.trim());

      // Navega a la pantalla de listado pasando el idAdmin
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ListarParqueaderosScreen(idAdmin: idAdmin),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingreso administrador'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _idAdminController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'ID del administrador',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Requerido';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Debe ser un número';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _ingresar,
                child: const Text('Ver mis parqueaderos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}