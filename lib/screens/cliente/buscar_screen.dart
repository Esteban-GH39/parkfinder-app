import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/reserva_service.dart';
import '../../services/sesion_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets_comunes.dart';
import 'detalle_parqueadero_screen.dart';
import 'login_screen.dart';
import 'pago_screen.dart';
import 'reservar_screen.dart';

/// HU-03: búsqueda de parqueaderos por zona (escrita o elegida de las existentes).
class BuscarScreen extends StatefulWidget {
  const BuscarScreen({
    super.key,
    ApiService? apiService,
    ReservaService? reservaService,
  }) : _apiService = apiService,
       _reservaService = reservaService;

  final ApiService? _apiService;
  final ReservaService? _reservaService;

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  final _zonaCtrl = TextEditingController();
  late final ApiService _apiService = widget._apiService ?? ApiService();
  late final ReservaService _reservaService =
      widget._reservaService ?? ReservaService();

  List<String> _zonas = [];
  List<dynamic> _resultados = [];
  List<Map<String, dynamic>> _pendientes = [];
  List<Map<String, dynamic>> _confirmadas = [];
  bool _cargando = false;
  bool _buscado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarZonas();
    _buscar(); // muestra todos al abrir
    _cargarPendientes();
  }

  /// HU-07: reservas retenidas sin pagar, para poder retomarlas.
  Future<void> _cargarPendientes() async {
    final clienteId = SesionService.instancia.id;
    if (clienteId == null) return;
    final pendientes = await _reservaService.pendientes(clienteId);
    final confirmadas = await _reservaService.confirmadas(clienteId);
    if (!mounted) return;
    setState(() {
      _pendientes = pendientes;
      _confirmadas = confirmadas;
    });
  }

  /// Al volver de reservar o pagar, los cupos y las pendientes ya cambiaron.
  void _refrescar() {
    _buscar();
    _cargarPendientes();
  }

  Future<void> _pagarPendiente(Map<String, dynamic> reserva) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PagoScreen(
          reserva: reserva,
          parqueadero: {
            'nombre': reserva['parqueaderoNombre'],
            'tarifaHora': reserva['tarifaHora'],
            'tarifaHoraMoto': reserva['tarifaHoraMoto'],
          },
        ),
      ),
    );
    if (mounted) _refrescar();
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

  /// HU-05: abre el detalle completo del parqueadero elegido.
  void _verDetalle(Map<String, dynamic> parqueadero) {
    final id = (parqueadero['id'] as num?)?.toInt();
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalleParqueaderoScreen(
          id: id,
          nombre: '${parqueadero['nombre'] ?? ''}',
        ),
      ),
    );
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
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) =>
                ReservarScreen(parqueadero: parqueadero, clienteId: clienteId),
          ),
        )
        .then((_) {
          if (mounted) _refrescar();
        });
  }

  void _salir() {
    SesionService.instancia.cerrar();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const EtiquetaRol(admin: false),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Hola, ${SesionService.instancia.nombre ?? ''}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textoSuave,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Encuentra tu mejor parqueadero cerca de ti',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const Key('botonSalir'),
                      customBorder: const CircleBorder(),
                      onTap: _salir,
                      child: const SizedBox(
                        width: 46,
                        height: 46,
                        child: Icon(Icons.logout, size: 20),
                      ),
                    ),
                  ),
                ],
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        for (final reserva in _pendientes) ...[
          _TarjetaPendiente(
            reserva: reserva,
            onPagar: () => _pagarPendiente(reserva),
          ),
          const SizedBox(height: 12),
        ],
        for (final reserva in _confirmadas) ...[
          _TarjetaConfirmada(reserva: reserva),
          const SizedBox(height: 12),
        ],
        for (final p in _resultados) ...[
          _TarjetaResultado(
            p: p as Map<String, dynamic>,
            onTap: () => _reservar(p),
            onDetalle: () => _verDetalle(p),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Una reserva ya pagada: muestra el código que el cliente le da al dueño al llegar.
class _TarjetaConfirmada extends StatelessWidget {
  const _TarjetaConfirmada({required this.reserva});
  final Map<String, dynamic> reserva;

  String get _cupos {
    final motos = ((reserva['cantidadMotos'] as num?) ?? 0).toInt();
    final total = ((reserva['cantidad'] as num?) ?? 1).toInt();
    final carros = total - motos;
    return [
      if (carros > 0) '$carros ${carros == 1 ? 'carro' : 'carros'}',
      if (motos > 0) '$motos ${motos == 1 ? 'moto' : 'motos'}',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) => Container(
    key: Key('reservaConfirmada_${reserva['id']}'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.exitoSuave,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline, color: AppColors.exito),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reserva confirmada',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '${reserva['parqueaderoNombre'] ?? ''} · $_cupos',
                style: const TextStyle(
                  color: AppColors.textoSuave,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Código',
              style: TextStyle(color: AppColors.textoSuave, fontSize: 11),
            ),
            Text(
              '${reserva['codigoReserva'] ?? '-'}',
              key: const Key('codigoReservaConfirmada'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    ),
  );
}

/// HU-07: una reserva retenida que falta pagar, con acceso directo al pago.
class _TarjetaPendiente extends StatelessWidget {
  const _TarjetaPendiente({required this.reserva, required this.onPagar});
  final Map<String, dynamic> reserva;
  final VoidCallback onPagar;

  String _hora(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'am' : 'pm'}';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.acentoSuave,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        const Icon(Icons.timer_outlined, color: AppColors.acento),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reserva pendiente de pago',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '${reserva['parqueaderoNombre'] ?? ''} · vence '
                '${_hora(reserva['expiraEn'] as String?)}',
                style: const TextStyle(
                  color: AppColors.textoSuave,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          key: const Key('botonPagarPendiente'),
          onPressed: onPagar,
          child: const Text('Pagar'),
        ),
      ],
    ),
  );
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
  const _TarjetaResultado({
    required this.p,
    required this.onTap,
    required this.onDetalle,
  });
  final Map<String, dynamic> p;
  final VoidCallback onTap;
  final VoidCallback onDetalle;

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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${p['zona'] ?? '-'}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (((p['capacidadMotos'] as num?) ?? 0) > 0) ...[
                          _EtiquetaCupos(
                            cupos: (p['cuposCarros'] as num?)?.toInt(),
                            tipo: 'carros',
                          ),
                          const SizedBox(width: 6),
                          _EtiquetaCupos(
                            cupos: (p['cuposMotos'] as num?)?.toInt(),
                            tipo: 'motos',
                          ),
                        ] else
                          _EtiquetaCupos(
                            cupos: (p['cuposDisponibles'] as num?)?.toInt(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (tarifa != null)
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
                  IconButton(
                    key: Key('detalle_${p['id']}'),
                    tooltip: 'Ver detalle',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.info_outline,
                      color: AppColors.textoSuave,
                    ),
                    onPressed: onDetalle,
                  ),
                ],
              ),
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

class _EtiquetaCupos extends StatelessWidget {
  const _EtiquetaCupos({required this.cupos, this.tipo});
  final int? cupos;

  /// 'carros' o 'motos' cuando el parqueadero separa los dos; null = cupos sin distinción.
  final String? tipo;

  @override
  Widget build(BuildContext context) {
    if (cupos == null) return const SizedBox.shrink();
    final hay = cupos! > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: hay ? AppColors.exitoSuave : AppColors.errorSuave,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        hay ? '$cupos ${tipo ?? 'cupos'}' : 'Sin ${tipo ?? 'cupos'}',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: hay ? AppColors.exito : AppColors.error,
        ),
      ),
    );
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
