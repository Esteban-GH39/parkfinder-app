import 'package:flutter/material.dart';

import '../../models/estadia.dart' show formatearPesos, formatearFechaHora;
import '../../models/historial.dart';
import '../../services/historial_service.dart';
import '../../services/sesion_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets_comunes.dart';

/// HU-24: historial de reservas e ingresos de los parqueaderos del dueño,
/// filtrado por día, semana o mes y, opcionalmente, por parqueadero.
class HistorialIngresosScreen extends StatefulWidget {
  const HistorialIngresosScreen({
    super.key,
    this.parqueaderos = const [],
    HistorialService? historialService,
    int? adminId,
    DateTime? hoy,
  }) : _servicio = historialService,
       _adminId = adminId,
       _hoy = hoy;

  /// Parqueaderos del dueño ({id, nombre}) para el filtro.
  final List<Map<String, dynamic>> parqueaderos;
  final HistorialService? _servicio;
  final int? _adminId;
  final DateTime? _hoy;

  @override
  State<HistorialIngresosScreen> createState() =>
      _HistorialIngresosScreenState();
}

enum _Vista { reservas, cobros }

class _HistorialIngresosScreenState extends State<HistorialIngresosScreen> {
  late final HistorialService _servicio =
      widget._servicio ?? HistorialService();
  late final int? _adminId = widget._adminId ?? SesionService.instancia.adminId;

  PeriodoHistorial _periodo = PeriodoHistorial.dia;
  late DateTime _fecha = widget._hoy ?? DateTime.now();
  int? _parqueaderoId;
  _Vista _vista = _Vista.reservas;

  Historial? _historial;
  bool _cargando = true;
  String? _error;
  int _consulta = 0;

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  Future<void> _consultar() async {
    final adminId = _adminId;
    if (adminId == null) {
      setState(() {
        _cargando = false;
        _error = 'Tu cuenta de dueño no tiene un perfil asociado.';
      });
      return;
    }
    // Si el usuario cambia de filtro rápido, solo cuenta la última respuesta
    final consulta = ++_consulta;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final historial = await _servicio.consultar(
        adminId: adminId,
        periodo: _periodo,
        fecha: _fecha,
        parqueaderoId: _parqueaderoId,
      );
      if (!mounted || consulta != _consulta) return;
      setState(() {
        _historial = historial;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted || consulta != _consulta) return;
      setState(() {
        _cargando = false;
        _error = '$e'.replaceFirst('Exception: ', '');
      });
    }
  }

  void _cambiarPeriodo(PeriodoHistorial p) {
    setState(() => _periodo = p);
    _consultar();
  }

  void _mover(int pasos) {
    setState(() => _fecha = _periodo.mover(_fecha, pasos));
    _consultar();
  }

  void _cambiarParqueadero(int? id) {
    setState(() => _parqueaderoId = id);
    _consultar();
  }

  @override
  Widget build(BuildContext context) {
    final h = _historial;
    return Scaffold(
      appBar: AppBar(title: const Text('Historial e ingresos')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _consultar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              SegmentedButton<PeriodoHistorial>(
                key: const Key('filtroPeriodo'),
                segments: [
                  for (final p in PeriodoHistorial.values)
                    ButtonSegment(
                      value: p,
                      label: Text(p.etiqueta, key: Key('periodo_${p.api}')),
                    ),
                ],
                selected: {_periodo},
                showSelectedIcon: false,
                onSelectionChanged: (s) => _cambiarPeriodo(s.first),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    key: const Key('periodoAnterior'),
                    onPressed: () => _mover(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      h == null ? '' : _textoRango(h.desde, h.hasta),
                      key: const Key('rangoPeriodo'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('periodoSiguiente'),
                    onPressed: () => _mover(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              if (widget.parqueaderos.length > 1) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  key: const Key('filtroParqueadero'),
                  initialValue: _parqueaderoId,
                  decoration: const InputDecoration(labelText: 'Parqueadero'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos mis parqueaderos'),
                    ),
                    for (final p in widget.parqueaderos)
                      DropdownMenuItem(
                        value: (p['id'] as num).toInt(),
                        child: Text('${p['nombre'] ?? ''}'),
                      ),
                  ],
                  onChanged: _cambiarParqueadero,
                ),
              ],
              const SizedBox(height: 16),
              if (_error != null) ...[
                AvisoError(texto: _error!),
                const SizedBox(height: 16),
              ],
              if (_cargando && h == null)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (h != null) ...[
                if (_cargando) const LinearProgressIndicator(minHeight: 2),
                _Resumen(h: h),
                if (_periodo != PeriodoHistorial.dia) ...[
                  const SizedBox(height: 12),
                  _Desglose(h: h, periodo: _periodo),
                ],
                const SizedBox(height: 20),
                SegmentedButton<_Vista>(
                  segments: [
                    ButtonSegment(
                      value: _Vista.reservas,
                      label: Text('Reservas (${h.reservas.length})'),
                    ),
                    ButtonSegment(
                      value: _Vista.cobros,
                      label: Text('Vehículos (${h.cobros.length})'),
                    ),
                  ],
                  selected: {_vista},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _vista = s.first),
                ),
                const SizedBox(height: 12),
                if (_vista == _Vista.reservas) ...[
                  if (h.reservas.isEmpty)
                    const _Vacio(texto: 'No hubo reservas en este periodo'),
                  for (final r in h.reservas) ...[
                    _TarjetaReserva(r: r),
                    const SizedBox(height: 10),
                  ],
                ] else ...[
                  if (h.cobros.isEmpty)
                    const _Vacio(
                      texto: 'Ningún vehículo pagó su salida en este periodo',
                    ),
                  for (final c in h.cobros) ...[
                    _TarjetaCobro(c: c),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  static const _meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static String _corta(DateTime d) => '${d.day} ${_meses[d.month - 1]}';

  String _textoRango(DateTime desde, DateTime hasta) => switch (_periodo) {
    PeriodoHistorial.dia => '${_corta(desde)} ${desde.year}',
    PeriodoHistorial.semana =>
      '${_corta(desde)} – ${_corta(hasta)} ${hasta.year}',
    PeriodoHistorial.mes => '${_mesLargo(desde.month)} ${desde.year}',
  };

  static String _mesLargo(int mes) => const [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ][mes - 1];
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.h});
  final Historial h;

  @override
  Widget build(BuildContext context) => TarjetaBlanca(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ingresos del periodo',
          style: TextStyle(color: AppColors.textoSuave, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          formatearPesos(h.ingresosTotales),
          key: const Key('ingresosTotales'),
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Dato(
                key: const Key('ingresosReservas'),
                titulo: 'Por reservas',
                valor: formatearPesos(h.ingresosReservas),
                detalle:
                    '${h.reservasPagadas} pagada${h.reservasPagadas == 1 ? '' : 's'} de ${h.totalReservas}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Dato(
                key: const Key('ingresosEstadias'),
                titulo: 'Por estadías',
                valor: formatearPesos(h.ingresosEstadias),
                detalle:
                    '${h.vehiculosCobrados} vehículo${h.vehiculosCobrados == 1 ? '' : 's'}',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Dato extends StatelessWidget {
  const _Dato({
    super.key,
    required this.titulo,
    required this.valor,
    required this.detalle,
  });
  final String titulo;
  final String valor;
  final String detalle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.fondo,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 12, color: AppColors.textoSuave),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        Text(
          detalle,
          style: const TextStyle(fontSize: 11.5, color: AppColors.textoSuave),
        ),
      ],
    ),
  );
}

/// Ingresos de cada día del periodo como barras horizontales.
/// En el mes solo se listan los días con ingresos para no mostrar 30 filas vacías.
class _Desglose extends StatelessWidget {
  const _Desglose({required this.h, required this.periodo});
  final Historial h;
  final PeriodoHistorial periodo;

  static const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final dias = periodo == PeriodoHistorial.mes
        ? h.desglose.where((d) => d.total > 0).toList()
        : h.desglose;
    final maximo = h.desglose.fold<double>(
      0,
      (m, d) => d.total > m ? d.total : m,
    );
    return TarjetaBlanca(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingresos por día',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (dias.isEmpty)
            const Text(
              'Sin ingresos en este periodo',
              style: TextStyle(color: AppColors.textoSuave),
            ),
          for (final d in dias)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      '${_dias[d.fecha.weekday - 1]} ${d.fecha.day}',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: maximo == 0 ? 0 : d.total / maximo,
                        minHeight: 10,
                        backgroundColor: AppColors.chip,
                        color: AppColors.acento,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 84,
                    child: Text(
                      formatearPesos(d.total),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TarjetaReserva extends StatelessWidget {
  const _TarjetaReserva({required this.r});
  final ReservaHistorial r;

  @override
  Widget build(BuildContext context) {
    final motos = r.cantidadMotos;
    final carros = r.cantidad - motos;
    final cupos = [
      if (carros > 0) '$carros ${carros == 1 ? 'carro' : 'carros'}',
      if (motos > 0) '$motos ${motos == 1 ? 'moto' : 'motos'}',
    ].join(' · ');
    return TarjetaBlanca(
      key: Key('historialReserva_${r.id}'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.clienteNombre ?? 'Cliente',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${r.parqueaderoNombre ?? ''} · $cupos',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textoSuave,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reservó ${formatearFechaHora(r.creadaEn)}'
                  '${r.codigoReserva != null ? ' · Código ${r.codigoReserva}' : ''}',
                  style: const TextStyle(fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                r.montoPagado > 0 ? formatearPesos(r.montoPagado) : '-',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              _etiquetaEstado(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _etiquetaEstado() => switch (r.estado) {
    'CONFIRMADA' when r.validadaEn != null => const _Etiqueta(
      texto: 'Atendida',
      fondo: AppColors.lila,
      color: Color(0xFF6B54C9),
    ),
    'CONFIRMADA' => const _Etiqueta(
      texto: 'Pagada',
      fondo: AppColors.exitoSuave,
      color: AppColors.exito,
    ),
    'RETENIDA' => const _Etiqueta(
      texto: 'Retenida',
      fondo: AppColors.acentoSuave,
      color: AppColors.acento,
    ),
    'CANCELADA' => const _Etiqueta(
      texto: 'Cancelada',
      fondo: AppColors.chip,
      color: AppColors.textoSuave,
    ),
    _ => const _Etiqueta(
      texto: 'Expirada',
      fondo: AppColors.chip,
      color: AppColors.textoSuave,
    ),
  };
}

class _TarjetaCobro extends StatelessWidget {
  const _TarjetaCobro({required this.c});
  final CobroEstadia c;

  @override
  Widget build(BuildContext context) {
    final horas = c.minutos ~/ 60;
    final mins = c.minutos % 60;
    final tiempo = horas > 0 ? '$horas h $mins min' : '$mins min';
    return TarjetaBlanca(
      key: Key('historialCobro_${c.id}'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            c.tipoVehiculo == 'MOTO'
                ? Icons.two_wheeler
                : Icons.directions_car_outlined,
            color: AppColors.acento,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.placa,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${c.parqueaderoNombre ?? ''} · $tiempo'
                  '${c.reservaId != null ? ' · Con reserva' : ''}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textoSuave,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Salió ${formatearFechaHora(c.salidaEn)}',
                  style: const TextStyle(fontSize: 12.5),
                ),
              ],
            ),
          ),
          Text(
            formatearPesos(c.valorCobrado),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.texto,
    required this.fondo,
    required this.color,
  });
  final String texto;
  final Color fondo;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: fondo,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      texto,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        const Icon(
          Icons.receipt_long_outlined,
          size: 34,
          color: AppColors.textoSuave,
        ),
        const SizedBox(height: 10),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textoSuave),
        ),
      ],
    ),
  );
}
