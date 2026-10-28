import 'package:flutter/material.dart';
import 'package:parkfinder_app/screens/admin/gestion_cupos_parqueadero_screen.dart';
import '../../models/parqueadero.dart';
import '../../services/parqueadero_service.dart';


class ListarParqueaderosScreen extends StatefulWidget {
  final int idAdmin;

  const ListarParqueaderosScreen({super.key, required this.idAdmin});

  @override
  State<ListarParqueaderosScreen> createState() =>
      _ListarParqueaderosScreenState();
}

class _ListarParqueaderosScreenState extends State<ListarParqueaderosScreen> {
  final ParqueaderoService _parqueaderoService = ParqueaderoService();
  late Future<List<Parqueadero>> _parqueaderosFuture;

  @override
  void initState() {
    super.initState();
    _cargarParqueaderos();
  }

  void _cargarParqueaderos() {
    setState(() {
      _parqueaderosFuture =
          _parqueaderoService.listarPorAdmin(widget.idAdmin);
    });
  }

  void _onParqueaderoSeleccionado(Parqueadero parqueadero) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GestionCuposParqueaderoScreen(
          parqueadero: parqueadero,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Pantalla Gestión Cupos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'Parqueaderos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Parqueadero>>(
                future: _parqueaderosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _cargarParqueaderos,
                              child: const Text('Reintentar'),
                            )
                          ],
                        ),
                      ),
                    );
                  }

                  final parqueaderos = snapshot.data ?? [];

                  if (parqueaderos.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay parqueaderos registrados para este admin.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    itemCount: parqueaderos.length,
                    separatorBuilder: (context, index) =>
                    const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final parqueadero = parqueaderos[index];

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _onParqueaderoSeleccionado(parqueadero),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.black,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  parqueadero.nombre.isNotEmpty
                                      ? parqueadero.nombre
                                      : 'Parqueadero ${parqueadero.id}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${parqueadero.direccion.isNotEmpty ? parqueadero.direccion : "Sin dirección"}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Capacidad total: ${parqueadero.capacidadTotal ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Encargado: ${parqueadero.encargado}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}