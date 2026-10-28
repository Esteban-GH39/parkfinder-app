import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/parqueadero.dart';
import '../../services/admin_service.dart';
import '../../services/sesion_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets_comunes.dart';
import '../cliente/login_screen.dart';
import 'gestion_cupos_parqueadero_screen.dart';

/// Vista del dueño: sus parqueaderos con los cupos que quedan y las reservas que reciben.
/// Se actualiza sola cada pocos segundos para ver llegar las reservas.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, AdminService? adminService})
    : _adminService = adminService;

  final AdminService? _adminService;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const _segundosEntreConsultas = 5;

  late final AdminService _servicio = widget._adminService ?? AdminService();
  final _sesion = SesionService.instancia;

  List<dynamic> _parqueaderos = [];
  List<dynamic> _reservas = [];
  bool _cargado = false;
  String? _error;
  Timer? _reloj;
  int _tics = 0;

  @override
  void initState() {
    super.initState();
    _consultar();
    // Cada segundo refresca las cuentas regresivas; cada 5 vuelve a consultar.
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _tics++;
      if (_tics % _segundosEntreConsultas == 0) {
        _consultar();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  Future<void> _consultar() async {
    final adminId = _sesion.adminId;
    if (adminId == null) {
      setState(() {
        _cargado = true;
        _error = 'Tu cuenta de dueño no tiene un perfil asociado.';
      });
      return;
    }
    try {
      // Primero las reservas: al listarlas el API libera las retenciones vencidas,
      // y así los cupos de los parqueaderos ya salen al día.
      final reservas = await _servicio.misReservas(adminId);
      final parqueaderos = await _servicio.misParqueaderos(adminId);
      if (!mounted) return;
      setState(() {
        _parqueaderos = parqueaderos;
        _reservas = reservas;
        _cargado = true;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargado = true;
        _error = 'No se pudo consultar tus parqueaderos. Reintentando...';
      });
    }
  }

  /// Gestión de cupos (HU-21): ingreso directo, liberar cupo y código de reserva.
  Future<void> _gestionarCupos(Map<String, dynamic> p) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            GestionCuposParqueaderoScreen(parqueadero: Parqueadero.fromJson(p)),
      ),
    );
    if (mounted) _consultar();
  }

  void _salir() {
    _sesion.cerrar();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final retenidas = _reservas.where(_estaRetenida).length;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${_sesion.nombre ?? ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textoSuave,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tus parqueaderos',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
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
            const SizedBox(height: 20),
            if (_error != null) ...[
              AvisoError(texto: _error!),
              const SizedBox(height: 16),
            ],
            if (!_cargado)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (_parqueaderos.isEmpty && _error == null)
                const _Vacio(
                  icono: Icons.local_parking,
                  texto: 'Aún no tienes parqueaderos asignados',
                ),
              for (final p in _parqueaderos) ...[
                _TarjetaParqueadero(
                  p: p as Map<String, dynamic>,
                  onTap: () => _gestionarCupos(p),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Reservas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (retenidas > 0)
                    _Etiqueta(
                      texto: '$retenidas en curso',
                      fondo: AppColors.acentoSuave,
                      color: AppColors.acento,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_reservas.isEmpty)
                const _Vacio(
                  icono: Icons.event_available_outlined,
                  texto: 'Todavía no hay reservas en tus parqueaderos',
                ),
              for (final r in _reservas) ...[
                _TarjetaReserva(r: r as Map<String, dynamic>),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static bool _estaRetenida(dynamic r) {
    final reserva = r as Map<String, dynamic>;
    return reserva['estado'] == 'RETENIDA' &&
        DateTime.parse('${reserva['expiraEn']}').isAfter(DateTime.now());
  }
}

class _TarjetaParqueadero extends StatelessWidget {
  const _TarjetaParqueadero({required this.p, required this.onTap});
  final Map<String, dynamic> p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      key: Key('abrirGestion_${p['id']}'),
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: _tarjeta(),
    ),
  );

  Widget _tarjeta() {
    final capacidad = (p['capacidadTotal'] as num?)?.toInt() ?? 0;
    final libres = (p['cuposDisponibles'] as num?)?.toInt() ?? 0;
    final ocupados = (capacidad - libres).clamp(0, capacidad);
    return TarjetaBlanca(
      key: Key('parqueaderoAdmin_${p['id']}'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.acentoSuave,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_parking, color: AppColors.acento),
              ),
              const SizedBox(width: 12),
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
                    Text(
                      '${p['zona'] ?? '-'} · ${p['direccion'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$libres',
                key: Key('cuposLibres_${p['id']}'),
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'de $capacidad cupos libres',
                style: const TextStyle(color: AppColors.textoSuave),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: capacidad == 0 ? 0 : ocupados / capacidad,
              minHeight: 8,
              backgroundColor: AppColors.chip,
              color: libres == 0 ? AppColors.error : AppColors.acento,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Gestionar cupos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.acento,
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: AppColors.acento),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaReserva extends StatelessWidget {
  const _TarjetaReserva({required this.r});
  final Map<String, dynamic> r;

  @override
  Widget build(BuildContext context) {
    final expira = DateTime.parse('${r['expiraEn']}');
    final restante = expira.difference(DateTime.now());
    final enCurso = r['estado'] == 'RETENIDA' && restante > Duration.zero;

    return TarjetaBlanca(
      key: Key('reserva_${r['id']}'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.lila,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r['clienteNombre'] ?? 'Cliente'}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${r['parqueaderoNombre'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textoSuave,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Llega ${_llegada(DateTime.parse('${r['fechaHoraLlegada']}'))}',
                  style: const TextStyle(fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          enCurso
              ? _Etiqueta(
                  texto: 'Retenida ${_mmss(restante)}',
                  fondo: AppColors.acentoSuave,
                  color: AppColors.acento,
                )
              : const _Etiqueta(
                  texto: 'Expirada',
                  fondo: AppColors.chip,
                  color: AppColors.textoSuave,
                ),
        ],
      ),
    );
  }

  static String _mmss(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String _llegada(DateTime d) {
    final hoy = DateTime.now();
    final manana = hoy.add(const Duration(days: 1));
    final hora =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (d.year == hoy.year && d.month == hoy.month && d.day == hoy.day) {
      return 'hoy $hora';
    }
    if (d.year == manana.year &&
        d.month == manana.month &&
        d.day == manana.day) {
      return 'mañana $hora';
    }
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} $hora';
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: fondo,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      texto,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.icono, required this.texto});
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Icon(icono, size: 34, color: AppColors.textoSuave),
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
