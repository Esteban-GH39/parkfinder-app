import 'package:flutter/material.dart';
import 'package:parkfinder_app/screens/admin/gestion_cupos_parqueadero_screen.dart';
import '../../models/parqueadero.dart';
import '../../services/comprobante_service.dart';
import '../../services/parqueadero_service.dart';


class ListarParqueaderosScreen extends StatefulWidget {
  final int idAdmin;

  /// Permite inyectar servicios falsos en las pruebas.
  final ParqueaderoService? parqueaderoService;
  final ComprobanteService? comprobanteService;

  const ListarParqueaderosScreen({
    super.key,
    required this.idAdmin,
    this.parqueaderoService,
    this.comprobanteService,
  });

  @override
  State<ListarParqueaderosScreen> createState() =>
      _ListarParqueaderosScreenState();
}

class _ListarParqueaderosScreenState extends State<ListarParqueaderosScreen> {
  late final ParqueaderoService _parqueaderoService =
      widget.parqueaderoService ?? ParqueaderoService();
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
          parqueaderoService: widget.parqueaderoService,
          comprobanteService: widget.comprobanteService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis parqueaderos'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Parqueadero>>(
        future: _parqueaderosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _cargarParqueaderos,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final parqueaderos = snapshot.data ?? [];

          if (parqueaderos.isEmpty) {
            return const Center(child: Text('Sin parqueaderos registrados'));
          }

          return ListView.builder(
            itemCount: parqueaderos.length,
            itemBuilder: (context, index) {
              final parqueadero = parqueaderos[index];
              return ListTile(
                title: Text(
                  parqueadero.nombre.isNotEmpty
                      ? parqueadero.nombre
                      : 'Parqueadero ${parqueadero.id}',
                ),
                subtitle: Text(
                  '${parqueadero.direccion.isNotEmpty ? parqueadero.direccion : "Sin dirección"}\n'
                  'Capacidad total: ${parqueadero.capacidadTotal ?? 0} · '
                  'Encargado: ${parqueadero.encargado}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _onParqueaderoSeleccionado(parqueadero),
              );
            },
          );
        },
      ),
    );
  }
}