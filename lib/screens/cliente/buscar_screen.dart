import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key});

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  final _zonaCtrl = TextEditingController();
  final _apiService = ApiService();
  List<dynamic> _resultados = [];
  bool _cargando = false;

  Future<void> _buscar() async {
    setState(() => _cargando = true);
    final resultados = await _apiService.buscarParqueaderos(
      zona: _zonaCtrl.text,
    );
    setState(() {
      _resultados = resultados;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar parqueaderos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _zonaCtrl,
                    decoration: const InputDecoration(labelText: 'Zona'),
                  ),
                ),
                IconButton(onPressed: _buscar, icon: const Icon(Icons.search)),
              ],
            ),
          ),
          if (_cargando) const CircularProgressIndicator(),
          Expanded(
            child: _resultados.isEmpty
                ? const Center(child: Text('Sin resultados'))
                : ListView.builder(
                    itemCount: _resultados.length,
                    itemBuilder: (context, i) {
                      final p = _resultados[i];
                      return ListTile(
                        title: Text(p['nombre'] ?? ''),
                        subtitle: Text(
                          'Cupos disponibles: ${p['cuposDisponibles'] ?? '-'}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
