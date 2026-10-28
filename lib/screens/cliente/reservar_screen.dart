import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/reserva_service.dart';
import '../../theme/app_theme.dart';

/// HU-06: elegir fecha y hora de llegada y retener un cupo mientras se paga.
class ReservarScreen extends StatefulWidget {
  const ReservarScreen({
    super.key,
    required this.parqueadero,
    required this.clienteId,
    this.llegadaInicial,
    ReservaService? reservaService,
  }) : _reservaService = reservaService;

  /// Parqueadero tal como lo devuelve `GET /parqueaderos`.
  final Map<String, dynamic> parqueadero;
  final int clienteId;

  /// Fecha y hora con las que se abre el formulario, si ya se conocen.
  final DateTime? llegadaInicial;
  final ReservaService? _reservaService;

  @override
  State<ReservarScreen> createState() => _ReservarScreenState();
}

class _ReservarScreenState extends State<ReservarScreen> {
  late final ReservaService _servicio =
      widget._reservaService ?? ReservaService();

  late DateTime _fecha;
  TimeOfDay? _hora;
  bool _cargando = false;
  String? _error;
  bool _sinCupo = false;

  Map<String, dynamic>? _reserva;
  Timer? _reloj;
  Duration _restante = Duration.zero;

  Map<String, dynamic> get _p => widget.parqueadero;

  @override
  void initState() {
    super.initState();
    final inicial = widget.llegadaInicial ?? DateTime.now();
    _fecha = DateTime(inicial.year, inicial.month, inicial.day);
    if (widget.llegadaInicial != null) {
      _hora = TimeOfDay(hour: inicial.hour, minute: inicial.minute);
    }
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  DateTime? get _llegada => _hora == null
      ? null
      : DateTime(_fecha.year, _fecha.month, _fecha.day, _hora!.hour, _hora!.minute);

  static DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  bool get _esHoy => _fecha == _soloFecha(DateTime.now());
  bool get _esManana =>
      _fecha == _soloFecha(DateTime.now().add(const Duration(days: 1)));

  Future<void> _elegirOtroDia() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 60)),
    );
    if (elegida != null) setState(() => _fecha = _soloFecha(elegida));
  }

  Future<void> _elegirHora() async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: _hora ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (elegida != null) setState(() => _hora = elegida);
  }

  Future<void> _reservar() async {
    final llegada = _llegada;
    if (llegada == null) return;
    setState(() {
      _cargando = true;
      _error = null;
      _sinCupo = false;
    });
    final resultado = await _servicio.reservar(
      clienteId: widget.clienteId,
      parqueaderoId: (_p['id'] as num).toInt(),
      llegada: llegada,
    );
    if (!mounted) return;
    if (resultado['success'] == true) {
      _reserva = resultado['data'] as Map<String, dynamic>;
      _iniciarReloj();
      setState(() => _cargando = false);
    } else {
      setState(() {
        _error = '${resultado['error']}';
        _sinCupo = resultado['sinCupo'] == true;
        _cargando = false;
      });
    }
  }

  void _iniciarReloj() {
    final expira = DateTime.parse('${_reserva!['expiraEn']}');
    void tick() {
      final falta = expira.difference(DateTime.now());
      setState(() => _restante = falta.isNegative ? Duration.zero : falta);
      if (falta.isNegative) _reloj?.cancel();
    }

    tick();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void _reservarDeNuevo() {
    _reloj?.cancel();
    setState(() {
      _reserva = null;
      _restante = Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const _BotonAtras(),
        title: const Text('Reservar cupo'),
      ),
      body: SafeArea(child: _reserva == null ? _formulario() : _retencion()),
    );
  }

  // ---------------------------------------------------------------- formulario

  Widget _formulario() {
    final puedeReservar = _llegada != null && !_cargando;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              _TarjetaParqueadero(parqueadero: _p),
              const SizedBox(height: 16),
              _Tarjeta(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hora de llegada',
                      style: TextStyle(
                        color: AppColors.textoSuave,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _Pastilla(
                          key: const Key('chipHoy'),
                          texto: 'Hoy',
                          activa: _esHoy,
                          onTap: () => setState(
                            () => _fecha = _soloFecha(DateTime.now()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Pastilla(
                          key: const Key('chipManana'),
                          texto: 'Mañana',
                          activa: _esManana,
                          onTap: () => setState(
                            () => _fecha = _soloFecha(
                              DateTime.now().add(const Duration(days: 1)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Pastilla(
                          key: const Key('chipOtroDia'),
                          texto: (_esHoy || _esManana)
                              ? 'Otro día'
                              : _textoFecha(_fecha),
                          activa: !(_esHoy || _esManana),
                          onTap: _elegirOtroDia,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    InkWell(
                      key: const Key('campoHora'),
                      onTap: _elegirHora,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: _hora == null
                            ? const Text(
                                '--:--',
                                style: TextStyle(
                                  fontSize: 50,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.chip,
                                  height: 1.1,
                                ),
                              )
                            : _HoraGrande(hora: _hora!),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hora == null
                          ? 'Toca para elegir la hora'
                          : 'Toca para cambiarla',
                      style: const TextStyle(
                        color: AppColors.textoSuave,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.lila,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.timer_outlined,
                            size: 19,
                            color: Color(0xFF6B54C9),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Tu cupo queda retenido unos minutos mientras pagas',
                            style: TextStyle(fontSize: 13, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _Aviso(texto: _error!, sinCupo: _sinCupo),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: FilledButton(
            key: const Key('botonReservar'),
            onPressed: puedeReservar ? _reservar : null,
            child: _cargando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Reservar cupo'),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- retención

  Widget _retencion() {
    final vencida = _restante == Duration.zero;
    final llegada = DateTime.parse('${_reserva!['fechaHoraLlegada']}');
    final total = DateTime.parse('${_reserva!['expiraEn']}').difference(
      DateTime.parse('${_reserva!['creadaEn']}'),
    );
    final avance = total.inSeconds == 0
        ? 0.0
        : (_restante.inSeconds / total.inSeconds).clamp(0.0, 1.0);
    final color = vencida ? AppColors.error : AppColors.acento;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              _Tarjeta(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: CircularProgressIndicator(
                              value: vencida ? 0 : avance,
                              strokeWidth: 12,
                              strokeCap: StrokeCap.round,
                              backgroundColor: vencida
                                  ? AppColors.errorSuave
                                  : AppColors.acentoSuave,
                              color: color,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                key: const Key('cuentaRegresiva'),
                                _mmss(_restante),
                                style: const TextStyle(
                                  fontSize: 46,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                vencida ? 'venció' : 'para pagar',
                                style: const TextStyle(
                                  color: AppColors.textoSuave,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      vencida ? 'La retención venció' : 'Cupo retenido',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vencida
                          ? 'El cupo volvió a estar disponible'
                          : 'Es tuyo hasta que se acabe el tiempo',
                      style: const TextStyle(
                        color: AppColors.textoSuave,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Tarjeta(
                child: Column(
                  children: [
                    _Fila('Parqueadero', '${_p['nombre'] ?? ''}'),
                    const Divider(height: 24, color: AppColors.borde),
                    _Fila(
                      'Llegada',
                      '${_textoFecha(llegada)} · ${_textoHora12(llegada.hour, llegada.minute)}',
                    ),
                    const Divider(height: 24, color: AppColors.borde),
                    _Fila('Reserva', '#${_reserva!['id']}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (vencida)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: FilledButton(
              key: const Key('botonReservarDeNuevo'),
              onPressed: _reservarDeNuevo,
              child: const Text('Reservar de nuevo'),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------------ formatos

  static const _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  String _textoFecha(DateTime d) => '${d.day} ${_meses[d.month - 1]}';

  String _mmss(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

String _textoHora12(int hora, int minuto) {
  final h = hora % 12 == 0 ? 12 : hora % 12;
  final m = minuto.toString().padLeft(2, '0');
  return '$h:$m ${hora < 12 ? 'am' : 'pm'}';
}

// ---------------------------------------------------------------- componentes

class _BotonAtras extends StatelessWidget {
  const _BotonAtras();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
    child: Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).maybePop(),
        child: const Icon(Icons.chevron_left, size: 26),
      ),
    ),
  );
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.superficie,
      borderRadius: BorderRadius.circular(28),
    ),
    child: child,
  );
}

class _TarjetaParqueadero extends StatelessWidget {
  const _TarjetaParqueadero({required this.parqueadero});
  final Map<String, dynamic> parqueadero;

  @override
  Widget build(BuildContext context) {
    final cupos = parqueadero['cuposDisponibles'];
    final tarifa = parqueadero['tarifaHora'];
    final hayCupos = cupos is num ? cupos > 0 : null;
    return _Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${parqueadero['nombre'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              if (tarifa != null) ...[
                const SizedBox(width: 12),
                Text.rich(
                  TextSpan(
                    text: '\$${_miles(tarifa)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    children: const [
                      TextSpan(
                        text: ' / hr',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textoSuave,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textoSuave,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${parqueadero['direccion'] ?? ''} · ${parqueadero['zona'] ?? ''}',
                  style: const TextStyle(
                    color: AppColors.textoSuave,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Abierto ${_hhmm(parqueadero['horaInicio'])} – ${_hhmm(parqueadero['horaFin'])}',
            style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
          ),
          if (hayCupos != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: hayCupos ? AppColors.acentoSuave : AppColors.errorSuave,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car_filled_outlined,
                    color: hayCupos ? AppColors.acento : AppColors.error,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    hayCupos ? '$cupos' : '0',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hayCupos ? 'cupos disponibles' : 'sin cupos disponibles',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _hhmm(dynamic hora) {
    final texto = '${hora ?? ''}';
    return texto.length >= 5 ? texto.substring(0, 5) : '--:--';
  }

  String _miles(dynamic valor) {
    final n = (valor as num).round().toString();
    return n.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }
}

class _Pastilla extends StatelessWidget {
  const _Pastilla({
    super.key,
    required this.texto,
    required this.activa,
    required this.onTap,
  });
  final String texto;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: activa ? AppColors.oscuro : AppColors.chip,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(
            texto,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
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

class _HoraGrande extends StatelessWidget {
  const _HoraGrande({required this.hora});
  final TimeOfDay hora;

  @override
  Widget build(BuildContext context) {
    final h = hora.hourOfPeriod == 0 ? 12 : hora.hourOfPeriod;
    final m = hora.minute.toString().padLeft(2, '0');
    return Text.rich(
      TextSpan(
        text: '$h:$m',
        style: const TextStyle(
          fontSize: 50,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
        children: [
          TextSpan(
            text: hora.period == DayPeriod.am ? ' am' : ' pm',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.etiqueta, this.valor);
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(etiqueta, style: const TextStyle(color: AppColors.textoSuave)),
      const SizedBox(width: 16),
      Flexible(
        child: Text(
          valor,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, required this.sinCupo});
  final String texto;
  final bool sinCupo;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.errorSuave,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          sinCupo ? Icons.block : Icons.error_outline,
          color: AppColors.error,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            sinCupo ? 'Este parqueadero se quedó sin cupos' : texto,
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}
