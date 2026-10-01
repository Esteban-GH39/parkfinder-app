import 'package:flutter/material.dart';

import '../../models/parqueadero.dart';
import '../../services/api_service.dart';
import 'editar_parqueadero_screen.dart';

/// HU-19: el administrador elige cuál parqueadero editar.
///
/// Es la puerta de entrada a [EditarParqueaderoScreen]. Cuando exista el login
/// (HU-17) debería listar solo el parqueadero del administrador autenticado.
class ListaParqueaderosScreen extends StatefulWidget {
  const ListaParqueaderosScreen({super.key, this.apiService});

  /// Permite inyectar un servicio falso en las pruebas.
  final ApiService? apiService;

  @override
  State<ListaParqueaderosScreen> createState() =>
      _ListaParqueaderosScreenState();
}

class _ListaParqueaderosScreenState extends State<ListaParqueaderosScreen> {
  late final ApiService _apiService = widget.apiService ?? ApiService();

  List<Parqueadero> _parqueaderos = [];
  bool _cargando = true;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });

    final resultado = await _apiService.listarParqueaderos();

    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (resultado['success'] == true) {
        _parqueaderos = resultado['data'] as List<Parqueadero>;
      } else {
        _errorMensaje = resultado['error']?.toString();
      }
    });
  }

  Future<void> _editar(Parqueadero parqueadero) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarParqueaderoScreen(
          parqueadero: parqueadero,
          apiService: widget.apiService,
        ),
      ),
    );
    // Al volver se recarga: la edición pudo cambiar lo que muestra la lista.
    if (mounted) await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis parqueaderos'),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMensaje != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMensaje!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    if (_parqueaderos.isEmpty) {
      return const Center(child: Text('No hay parqueaderos registrados'));
    }
    return ListView.separated(
      itemCount: _parqueaderos.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final p = _parqueaderos[i];
        return ListTile(
          title: Text(p.nombre),
          subtitle: Text('${p.zona} · ${p.direccion}'),
          trailing: const Icon(Icons.edit),
          onTap: () => _editar(p),
        );
      },
    );
  }
}
