import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/parqueadero.dart';
import '../../services/calificacion_service.dart';
import '../../services/parqueadero_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets_comunes.dart';
import 'ruta_screen.dart';

/// HU-05: detalle completo de un parqueadero.
class DetalleParqueaderoScreen extends StatefulWidget {
  const DetalleParqueaderoScreen({
    super.key,
    required this.id,
    this.nombre,
    ParqueaderoService? servicio,
    CalificacionService? calificacionService,
  }) : _servicio = servicio,
       _calificacionService = calificacionService;

  final int id;
  final String? nombre;
  final ParqueaderoService? _servicio;
  final CalificacionService? _calificacionService;

  @override
  State<DetalleParqueaderoScreen> createState() =>
      _DetalleParqueaderoScreenState();
}

class _DetalleParqueaderoScreenState extends State<DetalleParqueaderoScreen> {
  late final ParqueaderoService _servicio =
      widget._servicio ?? ParqueaderoService();

  late final CalificacionService _calificaciones =
      widget._calificacionService ?? CalificacionService();

  /// HU-13: `{promedio, total, calificaciones}`; null si aún no cargó o falló.
  Map<String, dynamic>? _resumen;

  Parqueadero? _p;
  String _horaFin = '';
  bool _cargando = true;
  bool _noExiste = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
      _noExiste = false;
    });
    try {
      final json = await _servicio.obtenerDetalle(widget.id);
      if (!mounted) return;
      if (json == null) {
        setState(() {
          _noExiste = true;
          _cargando = false;
        });
        return;
      }
      setState(() {
        _p = Parqueadero.fromJson(json);
        // El back devuelve horaFin; el modelo lee horaFinal.
        _horaFin = '${json['horaFin'] ?? json['horaFinal'] ?? ''}';
        _cargando = false;
      });
      _cargarResumen();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo consultar el detalle. Intenta de nuevo.';
        _cargando = false;
      });
    }
  }

  /// Si falla la consulta de calificaciones el detalle sigue funcionando sin ellas.
  Future<void> _cargarResumen() async {
    try {
      final resumen = await _calificaciones.resumen(widget.id);
      if (!mounted) return;
      setState(() => _resumen = resumen);
    } catch (_) {
      if (!mounted) return;
      setState(() => _resumen = null);
    }
  }

  String _fechaCorta(dynamic iso) {
    final d = DateTime.tryParse('${iso ?? ''}');
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _estrellas(int n) => '★' * n + '☆' * (5 - n);

  List<Widget> _seccionCalificaciones() {
    final r = _resumen;
    final lista = ((r?['calificaciones'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final total = ((r?['total'] as num?) ?? 0).toInt();
    final promedio = (r?['promedio'] as num?)?.toDouble();
    return [
      TarjetaBlanca(
        key: const Key('seccionCalificaciones'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star_border, size: 20, color: AppColors.textoSuave),
                SizedBox(width: 8),
                Text(
                  'Calificación y comentarios',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (total == 0 || promedio == null)
              const Text(
                'Este parqueadero aún no tiene calificaciones',
                style: TextStyle(fontSize: 14),
              )
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    promedio.toStringAsFixed(1),
                    key: const Key('promedioCalificacion'),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '$total ${total == 1 ? 'opinión' : 'opiniones'}',
                      style: const TextStyle(color: AppColors.textoSuave),
                    ),
                  ),
                ],
              ),
              for (final c in lista) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${c['clienteNombre'] ?? 'Cliente'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      _fechaCorta(c['creadaEn']),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textoSuave,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _estrellas(((c['estrellas'] as num?) ?? 0).toInt()),
                  style: const TextStyle(color: AppColors.acento),
                ),
                if ((c['comentario'] ?? '').toString().trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${c['comentario']}'),
                  ),
              ],
            ],
          ],
        ),
      ),
    ];
  }

  String _hora(String? v) {
    final s = v ?? '';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  String _dinero(double v) {
    final s = v.toStringAsFixed(0);
    return '\$${s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
  }

  /// Mapa dentro de la app con la mejor ruta desde donde está el usuario.
  void _comoLlegar(Parqueadero p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RutaScreen(
          nombre: p.nombre,
          direccion: [p.direccion, if (p.zona.isNotEmpty) p.zona].join(', '),
          destino: (p.latitud != null && p.longitud != null)
              ? LatLng(p.latitud!, p.longitud!)
              : null,
        ),
      ),
    );
  }

  Future<void> _abrirMapa(Parqueadero p) async {
    // Con coordenadas se usan; si no, se busca por dirección.
    // Supuesto: los parqueaderos están en Bogotá.
    final consulta = (p.latitud != null && p.longitud != null)
        ? '${p.latitud},${p.longitud}'
        : [
            p.direccion,
            if (p.zona.isNotEmpty) p.zona,
            'Bogotá, Colombia',
          ].join(', ');
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': consulta,
    });
    var abierto = false;
    try {
      abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      abierto = false;
    }
    if (!abierto && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo abrir el mapa')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.nombre ?? 'Detalle del parqueadero')),
      body: SafeArea(child: _contenido()),
    );
  }

  Widget _contenido() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvisoError(texto: _error!),
              const SizedBox(height: 12),
              FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    final p = _p;
    if (_noExiste || p == null) {
      return const Center(child: Text('Este parqueadero ya no existe'));
    }

    final tarifas = <String>[
      if (p.tarifaHora != null) 'Carro por hora: ${_dinero(p.tarifaHora!)}',
      if (p.tieneMotos)
        p.tarifaHoraMoto != null
            ? 'Moto por hora: ${_dinero(p.tarifaHoraMoto!)}'
            : 'Moto por hora: igual que el carro',
      if (p.tarifaDia != null) 'Por día: ${_dinero(p.tarifaDia!)}',
      if (p.tarifaNoche != null) 'Por noche: ${_dinero(p.tarifaNoche!)}',
    ];
    final inicio = _hora(p.horaInicio);
    final fin = _hora(_horaFin);
    final horario = (inicio.isEmpty && fin.isEmpty)
        ? 'No informado'
        : '$inicio a $fin';
    final total = p.capacidadTotal ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TarjetaBlanca(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.nombre,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Encargado: ${p.encargado}',
                style: const TextStyle(color: AppColors.textoSuave),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Seccion(
          icono: Icons.place_outlined,
          titulo: 'Ubicación',
          lineas: [p.direccion, 'Zona: ${p.zona.isEmpty ? '-' : p.zona}'],
          accion: Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                key: const Key('botonComoLlegar'),
                onPressed: () => _comoLlegar(p),
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Cómo llegar'),
              ),
              TextButton.icon(
                key: const Key('botonVerMapa'),
                onPressed: () => _abrirMapa(p),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Ver en Google Maps'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Seccion(
          icono: Icons.payments_outlined,
          titulo: 'Tarifas',
          lineas: tarifas.isEmpty ? ['No informadas'] : tarifas,
        ),
        const SizedBox(height: 12),
        _Seccion(icono: Icons.schedule, titulo: 'Horario', lineas: [horario]),
        const SizedBox(height: 12),
        _Seccion(
          icono: Icons.event_seat_outlined,
          titulo: 'Capacidad y disponibilidad',
          lineas: [
            'Capacidad total: $total cupos',
            'Disponibles: ${p.cuposDisponibles} de $total',
            if (p.tieneMotos) ...[
              'Carros: ${p.cuposCarros} de ${p.capacidadCarros}',
              'Motos: ${p.cuposMotos} de ${p.capacidadMotos}',
            ],
          ],
        ),
        const SizedBox(height: 12),
        // HU-13: promedio y comentarios de quienes ya usaron el parqueadero.
        ..._seccionCalificaciones(),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.icono,
    required this.titulo,
    required this.lineas,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final List<String> lineas;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => TarjetaBlanca(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 20, color: AppColors.textoSuave),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final l in lineas)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(l, style: const TextStyle(fontSize: 14, height: 1.35)),
          ),
        if (accion != null) accion!,
      ],
    ),
  );
}
