import 'package:flutter/material.dart';

import '../../services/api_service.dart';

/// HU-03: búsqueda de parqueaderos por zona (escrita o elegida de las existentes).
class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key, ApiService? apiService})
    : _apiService = apiService;

  final ApiService? _apiService;

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  final _zonaCtrl = TextEditingController();
  late final ApiService _apiService = widget._apiService ?? ApiService();

  List<String> _zonas = [];
  List<dynamic> _resultados = [];
  bool _cargando = false;
  bool _buscado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarZonas();
    _buscar(); // muestra todos al abrir
  }

  @override
  void dispose() {
    _zonaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarZonas() async {
    final zonas = await _apiService.obtenerZonas();
    if (!mounted) return;
    setState(() => _zonas = zonas);
  }

  Future<void> _buscar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resultados = await _apiService.buscarParqueaderos(
        zona: _zonaCtrl.text,
      );
      if (!mounted) return;
      setState(() {
        _resultados = resultados;
        _buscado = true;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resultados = [];
        _error = 'No se pudo consultar los parqueaderos. Intenta de nuevo.';
        _cargando = false;
      });
    }
  }

  void _elegirZona(String zona) {
    _zonaCtrl.text = zona;
    _buscar();
  }

  String _mensajeVacio() {
    final zona = _zonaCtrl.text.trim();
    return zona.isEmpty
        ? 'Aún no hay parqueaderos registrados'
        : 'No se encontraron parqueaderos en la zona "$zona"';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar parqueaderos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('campoZona'),
                    controller: _zonaCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _buscar(),
                    decoration: const InputDecoration(
                      labelText: 'Zona',
                      hintText: 'Escribe o elige una zona',
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('botonBuscar'),
                  onPressed: _buscar,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          if (_zonas.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _zonas.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ActionChip(
                  label: Text(_zonas[i]),
                  onPressed: () => _elegirZona(_zonas[i]),
                ),
              ),
            ),
          if (_cargando) const LinearProgressIndicator(),
          Expanded(child: _contenido()),
        ],
      ),
    );
  }

  Widget _contenido() {
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    if (_buscado && _resultados.isEmpty && !_cargando) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_mensajeVacio(), textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.builder(
      itemCount: _resultados.length,
      itemBuilder: (context, i) {
        final p = _resultados[i] as Map<String, dynamic>;
        final tarifa = p['tarifaHora'];
        return ListTile(
          leading: const Icon(Icons.local_parking),
          title: Text('${p['nombre'] ?? ''}'),
          subtitle: Text(
            '${p['direccion'] ?? ''}\nZona: ${p['zona'] ?? '-'}'
            ' · Capacidad: ${p['capacidadTotal'] ?? '-'}'
            '${tarifa != null ? ' · \$$tarifa/hora' : ''}',
          ),
          isThreeLine: true,
        );
      },
    );
  }
}
