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
        title: const Text('Ingreso Administrador'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.local_parking_rounded,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Gestión de Parqueaderos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingrese su ID de administrador para continuar',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _idAdminController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'ID Administrador',
                  hintText: 'Ej. 1',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {

                    return 'Por favor ingrese el ID';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Ingrese un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _ingresar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Ver mis parqueaderos',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}