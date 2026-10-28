import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/sesion_service.dart';
import '../../theme/app_theme.dart';
import 'reservar_screen.dart';

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
    // Tocar la zona ya elegida quita el filtro.
    _zonaCtrl.text = _zonaCtrl.text.trim() == zona ? '' : zona;
    _buscar();
  }

  /// HU-06: abre la reserva del parqueadero elegido.
  void _reservar(Map<String, dynamic> parqueadero) {
    final clienteId = SesionService.instancia.id;
    if (clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo identificar tu cuenta. Inicia sesión de nuevo.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ReservarScreen(parqueadero: parqueadero, clienteId: clienteId),
      ),
    );
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Text(
                'Encuentra tu mejor parqueadero cerca de ti',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _CampoBusqueda(controller: _zonaCtrl, onBuscar: _buscar),
            ),
            if (_zonas.isNotEmpty)
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  itemCount: _zonas.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => _ChipZona(
                    zona: _zonas[i],
                    activa: _zonaCtrl.text.trim() == _zonas[i],
                    onTap: () => _elegirZona(_zonas[i]),
                  ),
                ),
              ),
            if (_cargando) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _contenido()),
          ],
        ),
      ),
    );
  }

  Widget _contenido() {
    if (_error != null) {
      return _Mensaje(icono: Icons.cloud_off_outlined, texto: _error!);
    }
    if (_buscado && _resultados.isEmpty && !_cargando) {
      return _Mensaje(icono: Icons.search_off, texto: _mensajeVacio());
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: _resultados.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = _resultados[i] as Map<String, dynamic>;
        return _TarjetaResultado(p: p, onTap: () => _reservar(p));
      },
    );
  }
}

class _CampoBusqueda extends StatelessWidget {
  const _CampoBusqueda({required this.controller, required this.onBuscar});
  final TextEditingController controller;
  final VoidCallback onBuscar;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 20, right: 6),
    decoration: BoxDecoration(
      color: AppColors.superficie,
      borderRadius: BorderRadius.circular(32),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('campoZona'),
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onBuscar(),
            decoration: const InputDecoration(
              hintText: 'Escribe o elige una zona',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
        Material(
          color: AppColors.oscuro,
          shape: const CircleBorder(),
          child: InkWell(
            key: const Key('botonBuscar'),
            customBorder: const CircleBorder(),
            onTap: onBuscar,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.search, color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ChipZona extends StatelessWidget {
  const _ChipZona({
    required this.zona,
    required this.activa,
    required this.onTap,
  });
  final String zona;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: activa ? AppColors.oscuro : AppColors.chip,
    shape: const StadiumBorder(),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Center(
          child: Text(
            zona,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: activa ? Colors.white : AppColors.textoSuave,
            ),
          ),
        ),
      ),
    ),
  );
}

class _TarjetaResultado extends StatelessWidget {
  const _TarjetaResultado({required this.p, required this.onTap});
  final Map<String, dynamic> p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tarifa = p['tarifaHora'];
    return Material(
      color: AppColors.superficie,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: Key('parqueadero_${p['id']}'),
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.acentoSuave,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_parking,
                  color: AppColors.acento,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p['nombre'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppColors.textoSuave,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${p['direccion'] ?? ''}',
                            style: const TextStyle(
                              color: AppColors.textoSuave,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${p['zona'] ?? '-'} · Capacidad ${p['capacidadTotal'] ?? '-'}',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (tarifa != null) ...[
                const SizedBox(width: 8),
                Text.rich(
                  TextSpan(
                    text: '\$${_miles(tarifa)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    children: const [
                      TextSpan(
                        text: '\n/ hr',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textoSuave,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _miles(dynamic valor) {
    final n = (valor as num).round().toString();
    return n.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.icono, required this.texto});
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.chip,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: AppColors.textoSuave, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textoSuave, height: 1.4),
          ),
        ],
      ),
    ),
  );
}
