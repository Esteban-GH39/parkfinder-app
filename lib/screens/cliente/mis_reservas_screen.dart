import 'package:flutter/material.dart';

import '../../services/calificacion_service.dart';
import '../../services/reserva_service.dart';
import '../../services/sesion_service.dart';
import '../../theme/app_theme.dart';
import 'calificar_screen.dart';
import 'pago_screen.dart';

/// Historial de reservas del cliente, separado de la búsqueda de parqueaderos.
/// Muestra todas sus reservas (por pagar, confirmadas, usadas y vencidas) con filtros por estado.
class MisReservasScreen extends StatefulWidget {
  const MisReservasScreen({
    super.key,
    ReservaService? reservaService,
    CalificacionService? calificacionService,
  }) : _reservaService = reservaService,
       _calificacionService = calificacionService;

  final ReservaService? _reservaService;
  final CalificacionService? _calificacionService;

  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

/// Estado tal como lo ve el cliente (el backend distingue RETENIDA, CONFIRMADA, EXPIRADA y CANCELADA).
enum _Estado { porPagar, confirmada, usada, vencida, cancelada }

enum _Filtro {
  todas('Todas'),
  porPagar('Por pagar'),
  confirmadas('Confirmadas'),
  pasadas('Pasadas');

  const _Filtro(this.etiqueta);
  final String etiqueta;
}

class _MisReservasScreenState extends State<MisReservasScreen> {
  late final ReservaService _reservaService =
      widget._reservaService ?? ReservaService();

  late final CalificacionService _calificacionService =
      widget._calificacionService ?? CalificacionService();

  List<Map<String, dynamic>> _reservas = [];

  /// HU-13: por parqueadero, `{puede, yaCalifico}` (solo de los parqueaderos con reservas usadas).
  final Map<int, Map<String, dynamic>> _permisos = {};
  _Filtro _filtro = _Filtro.todas;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final clienteId = SesionService.instancia.id;
    if (clienteId == null) {
      setState(() => _cargando = false);
      return;
    }
    setState(() => _cargando = true);
    final reservas = await _reservaService.historial(clienteId);
    if (!mounted) return;
    setState(() {
      _reservas = reservas;
      _cargando = false;
    });
    _cargarPermisos(clienteId);
  }

  /// Consulta si el cliente puede calificar cada parqueadero donde ya usó una reserva.
  Future<void> _cargarPermisos(int clienteId) async {
    final ids = _reservas
        .where((r) => _estado(r) == _Estado.usada)
        .map((r) => (r['parqueaderoId'] as num).toInt())
        .toSet();
    for (final id in ids) {
      final permiso = await _calificacionService.permiso(clienteId, id);
      if (!mounted) return;
      setState(() => _permisos[id] = permiso);
    }
  }

  Future<void> _calificar(Map<String, dynamic> reserva) async {
    final calificado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CalificarScreen(
          parqueaderoId: (reserva['parqueaderoId'] as num).toInt(),
          nombre: '${reserva['parqueaderoNombre'] ?? 'Parqueadero'}',
        ),
      ),
    );
    if (calificado == true && mounted) _cargar();
  }

  _Estado _estado(Map<String, dynamic> r) {
    switch (r['estado']) {
      case 'CONFIRMADA':
        return r['validadaEn'] != null ? _Estado.usada : _Estado.confirmada;
      case 'RETENIDA':
        final expira = DateTime.tryParse('${r['expiraEn'] ?? ''}');
        // Una retención que ya pasó su hora no se puede pagar aunque el servidor aún no la libere.
        return expira != null && expira.isBefore(DateTime.now())
            ? _Estado.vencida
            : _Estado.porPagar;
      case 'CANCELADA':
        return _Estado.cancelada;
      default:
        return _Estado.vencida;
    }
  }

  List<Map<String, dynamic>> get _filtradas => _reservas.where((r) {
    final e = _estado(r);
    switch (_filtro) {
      case _Filtro.todas:
        return true;
      case _Filtro.porPagar:
        return e == _Estado.porPagar;
      case _Filtro.confirmadas:
        return e == _Estado.confirmada;
      case _Filtro.pasadas:
        return e == _Estado.usada ||
            e == _Estado.vencida ||
            e == _Estado.cancelada;
    }
  }).toList();

  /// HU-10: pide confirmación y cancela; el servidor rechaza si ya pasó el tiempo límite.
  Future<void> _cancelar(Map<String, dynamic> reserva) async {
    final clienteId = SesionService.instancia.id;
    if (clienteId == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar la reserva?'),
        content: const Text('El cupo quedará libre y el código dejará de servir.'),
        actions: [
          TextButton(
            key: const Key('noCancelar'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            key: const Key('siCancelar'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    final resultado = await _reservaService.cancelar(
      (reserva['id'] as num).toInt(),
      clienteId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          resultado['success'] == true
              ? 'Reserva cancelada'
              : '${resultado['error']}',
        ),
      ),
    );
    _cargar();
  }

  Future<void> _pagar(Map<String, dynamic> reserva) async {
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
    if (mounted) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtradas;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis reservas')),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                itemCount: _Filtro.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _Filtro.values[i];
                  final activo = f == _filtro;
                  return Material(
                    color: activo ? AppColors.oscuro : AppColors.chip,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      key: Key('filtro_${f.name}'),
                      customBorder: const StadiumBorder(),
                      onTap: () => setState(() => _filtro = f),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Center(
                          child: Text(
                            f.etiqueta,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: activo
                                  ? Colors.white
                                  : AppColors.textoSuave,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_cargando) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _cargar,
                child: lista.isEmpty && !_cargando
                    ? ListView(
                        children: [
                          _Vacio(
                            texto: _reservas.isEmpty
                                ? 'Aún no has hecho reservas'
                                : 'No tienes reservas en "${_filtro.etiqueta}"',
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: lista.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final r = lista[i];
                          final e = _estado(r);
                          final permiso =
                              _permisos[(r['parqueaderoId'] as num?)?.toInt()];
                          return _TarjetaReserva(
                            reserva: r,
                            estado: e,
                            onPagar: e == _Estado.porPagar
                                ? () => _pagar(r)
                                : null,
                            onCancelar: e == _Estado.confirmada
                                ? () => _cancelar(r)
                                : null,
                            onCalificar:
                                e == _Estado.usada && permiso?['puede'] == true
                                ? () => _calificar(r)
                                : null,
                            yaCalificado:
                                e == _Estado.usada &&
                                permiso?['yaCalifico'] == true,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaReserva extends StatelessWidget {
  const _TarjetaReserva({
    required this.reserva,
    required this.estado,
    this.onPagar,
    this.onCancelar,
    this.onCalificar,
    this.yaCalificado = false,
  });
  final Map<String, dynamic> reserva;
  final _Estado estado;
  final VoidCallback? onPagar;
  final VoidCallback? onCancelar;
  final VoidCallback? onCalificar;
  final bool yaCalificado;

  (String, Color, Color, IconData) get _aspecto {
    switch (estado) {
      case _Estado.porPagar:
        return (
          'Por pagar',
          AppColors.acento,
          AppColors.acentoSuave,
          Icons.timer_outlined,
        );
      case _Estado.confirmada:
        return (
          'Confirmada',
          AppColors.exito,
          AppColors.exitoSuave,
          Icons.check_circle_outline,
        );
      case _Estado.usada:
        return (
          'Usada',
          AppColors.textoSuave,
          AppColors.chip,
          Icons.task_alt_outlined,
        );
      case _Estado.vencida:
        return (
          'Vencida',
          AppColors.error,
          AppColors.errorSuave,
          Icons.event_busy_outlined,
        );
      case _Estado.cancelada:
        return (
          'Cancelada',
          AppColors.textoSuave,
          AppColors.chip,
          Icons.cancel_outlined,
        );
    }
  }

  String get _cupos {
    final motos = ((reserva['cantidadMotos'] as num?) ?? 0).toInt();
    final total = ((reserva['cantidad'] as num?) ?? 1).toInt();
    final carros = total - motos;
    return [
      if (carros > 0) '$carros ${carros == 1 ? 'carro' : 'carros'}',
      if (motos > 0) '$motos ${motos == 1 ? 'moto' : 'motos'}',
    ].join(' · ');
  }

  String _fecha(dynamic iso) {
    final d = DateTime.tryParse('${iso ?? ''}');
    if (d == null) return '-';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} · $h:$m ${d.hour < 12 ? 'am' : 'pm'}';
  }

  @override
  Widget build(BuildContext context) {
    final (texto, color, fondo, icono) = _aspecto;
    final codigo = reserva['codigoReserva'];
    return Container(
      key: Key('reserva_${reserva['id']}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: fondo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icono, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      texto,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Reserva #${reserva['id']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textoSuave,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${reserva['parqueaderoNombre'] ?? 'Parqueadero'}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Llegada: ${_fecha(reserva['fechaHoraLlegada'])}',
            style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
          ),
          if (_cupos.isNotEmpty)
            Text(
              _cupos,
              style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
            ),
          if (estado == _Estado.porPagar)
            Text(
              'Vence: ${_fecha(reserva['expiraEn'])}',
              style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
            ),
          if (estado == _Estado.usada)
            Text(
              'Usada: ${_fecha(reserva['validadaEn'])}',
              style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
            ),
          if (estado == _Estado.confirmada && codigo != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.exitoSuave,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text(
                    'Código de reserva',
                    style: TextStyle(fontSize: 12, color: AppColors.textoSuave),
                  ),
                  const Spacer(),
                  Text(
                    '$codigo',
                    key: Key('codigoReserva_${reserva['id']}'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onCancelar != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: Key('botonCancelar_${reserva['id']}'),
                onPressed: onCancelar,
                child: const Text('Cancelar reserva'),
              ),
            ),
          ],
          if (onCalificar != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: Key('botonCalificar_${reserva['id']}'),
                onPressed: onCalificar,
                icon: const Icon(Icons.star_outline),
                label: const Text('Calificar'),
              ),
            ),
          ],
          if (yaCalificado) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.star, size: 16, color: AppColors.exito),
                SizedBox(width: 6),
                Text(
                  'Ya calificaste este parqueadero',
                  style: TextStyle(fontSize: 12, color: AppColors.textoSuave),
                ),
              ],
            ),
          ],
          if (onPagar != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: Key('botonPagar_${reserva['id']}'),
                onPressed: onPagar,
                child: const Text('Pagar'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.chip,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.textoSuave,
            size: 30,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textoSuave, height: 1.4),
        ),
      ],
    ),
  );
}
