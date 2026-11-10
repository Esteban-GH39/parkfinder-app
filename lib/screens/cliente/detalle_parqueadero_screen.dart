import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/parqueadero.dart';
import '../../services/parqueadero_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets_comunes.dart';

/// HU-05: detalle completo de un parqueadero.
class DetalleParqueaderoScreen extends StatefulWidget {
  const DetalleParqueaderoScreen({
    super.key,
    required this.id,
    this.nombre,
    ParqueaderoService? servicio,
  }) : _servicio = servicio;

  final int id;
  final String? nombre;
  final ParqueaderoService? _servicio;

  @override
  State<DetalleParqueaderoScreen> createState() =>
      _DetalleParqueaderoScreenState();
}

class _DetalleParqueaderoScreenState extends State<DetalleParqueaderoScreen> {
  late final ParqueaderoService _servicio =
      widget._servicio ?? ParqueaderoService();

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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo consultar el detalle. Intenta de nuevo.';
        _cargando = false;
      });
    }
  }

  String _hora(String? v) {
    final s = v ?? '';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  String _dinero(double v) {
    final s = v.toStringAsFixed(0);
    return '\$${s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
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
          accion: TextButton.icon(
            key: const Key('botonVerMapa'),
            onPressed: () => _abrirMapa(p),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Ver en el mapa'),
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
        // HU-13 (calificaciones y comentarios) aún no existe: aviso fijo.
        const _Seccion(
          icono: Icons.star_border,
          titulo: 'Calificación y comentarios',
          lineas: ['Este parqueadero aún no tiene calificaciones'],
        ),
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
