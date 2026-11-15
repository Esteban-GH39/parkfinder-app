import 'package:flutter/material.dart';

import '../../models/estadia.dart';
import '../../models/parqueadero.dart';
import '../../services/estadia_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets_comunes.dart';
import 'campo_placa.dart';

/// Liberar cupo: el administrador digita la placa del vehículo que sale, el
/// sistema calcula cuánto debe pagar por el tiempo transcurrido y, al confirmar,
/// registra la salida y libera el cupo. Cierra devolviendo la [Liquidacion]
/// cerrada (o null si no se liberó ningún cupo).
class SalidaVehiculoScreen extends StatefulWidget {
  const SalidaVehiculoScreen({
    super.key,
    required this.parqueadero,
    this.estadiaService,
  });

  final Parqueadero parqueadero;

  /// Permite inyectar un servicio falso en las pruebas.
  final EstadiaService? estadiaService;

  @override
  State<SalidaVehiculoScreen> createState() => _SalidaVehiculoScreenState();
}

class _SalidaVehiculoScreenState extends State<SalidaVehiculoScreen> {
  late final EstadiaService _servicio =
      widget.estadiaService ?? EstadiaService();
  final _placaCtrl = TextEditingController();

  List<Liquidacion> _adentro = [];
  bool _cargandoAdentro = true;

  /// Cobro consultado (aún sin liberar) o ya cerrado.
  Liquidacion? _liquidacion;
  bool _cargando = false;
  String? _error;

  int get _parqueaderoId => widget.parqueadero.id;
  int get _adminId => widget.parqueadero.fk_parqueadero_admin;
  bool get _cerrada => _liquidacion?.cerrada == true;

  @override
  void initState() {
    super.initState();
    _cargarAdentro();
  }

  @override
  void dispose() {
    _placaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarAdentro() async {
    try {
      final lista = await _servicio.listarActivas(
        parqueaderoId: _parqueaderoId,
        adminId: _adminId,
      );
      if (!mounted) return;
      setState(() => _adentro = lista);
    } catch (_) {
      // La lista solo ayuda a elegir la placa; sin ella se puede digitar
    } finally {
      if (mounted) setState(() => _cargandoAdentro = false);
    }
  }

  Future<void> _calcular() async {
    if (!placaValida(_placaCtrl.text)) {
      setState(() => _error = mensajePlacaInvalida);
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
      _liquidacion = null;
    });
    try {
      final liquidacion = await _servicio.consultarCobro(
        parqueaderoId: _parqueaderoId,
        adminId: _adminId,
        placa: normalizarPlaca(_placaCtrl.text),
      );
      if (!mounted) return;
      setState(() => _liquidacion = liquidacion);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _confirmarSalida() async {
    final consulta = _liquidacion;
    if (consulta == null) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final cerrada = await _servicio.registrarSalida(
        parqueaderoId: _parqueaderoId,
        adminId: _adminId,
        placa: consulta.placa,
      );
      if (!mounted) return;
      setState(() => _liquidacion = cerrada);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _elegir(Liquidacion vehiculo) {
    _placaCtrl.text = vehiculo.placa;
    _calcular();
  }

  @override
  Widget build(BuildContext context) {
    // Si ya se liberó el cupo, al volver se avisa a la gestión de cupos
    return PopScope<Object?>(
      canPop: !_cerrada,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _liquidacion);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Liberar cupo'), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TarjetaBlanca(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.parqueadero.nombre.isNotEmpty
                          ? widget.parqueadero.nombre
                          : 'Parqueadero ${widget.parqueadero.id}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textoSuave,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Digita la placa del vehículo que sale para calcular '
                      'cuánto debe pagar.',
                      style: TextStyle(fontSize: 13.5, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    CampoPlaca(
                      key: const Key('placaSalida'),
                      controller: _placaCtrl,
                      enabled: !_cargando && !_cerrada,
                      onSubmitted: (_) => _calcular(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      AvisoError(texto: _error!),
                    ],
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _cargando || _cerrada ? null : _calcular,
                      child: _cargando && _liquidacion == null
                          ? const CargandoEnBoton()
                          : const Text('Calcular cobro'),
                    ),
                  ],
                ),
              ),
              if (_liquidacion != null) ...[
                const SizedBox(height: 16),
                _DetalleCobro(liquidacion: _liquidacion!),
                const SizedBox(height: 20),
                if (_cerrada)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _liquidacion),
                    child: const Text('Listo'),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.exito,
                    ),
                    onPressed: _cargando ? null : _confirmarSalida,
                    child: _cargando
                        ? const CargandoEnBoton()
                        : const Text('Confirmar pago y liberar cupo'),
                  ),
              ],
              if (!_cerrada) ...[
                const SizedBox(height: 24),
                _VehiculosAdentro(
                  cargando: _cargandoAdentro,
                  vehiculos: _adentro,
                  onElegir: _cargando ? null : _elegir,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiempo, tarifas y valor a pagar.
class _DetalleCobro extends StatelessWidget {
  const _DetalleCobro({required this.liquidacion});
  final Liquidacion liquidacion;

  @override
  Widget build(BuildContext context) {
    final l = liquidacion;
    final filas = <String, String>{
      'Placa': l.placa,
      'Vehículo': l.tipoVehiculo.etiqueta,
      if (l.reservaId != null) 'Reserva': '#${l.reservaId}',
      'Ingreso': formatearFechaHora(l.ingresoEn),
      l.cerrada ? 'Salida' : 'Hora actual': formatearFechaHora(l.salidaEn),
      'Tiempo': l.tiempoTexto,
      'Tarifa hora': l.tarifaHora == null ? '-' : formatearPesos(l.tarifaHora!),
      'Valor minuto': '\$${l.valorMinuto.toStringAsFixed(2)}',
      if (l.minutosNocturnos > 0)
        'Tiempo nocturno': formatearMinutos(l.minutosNocturnos),
    };
    final notas = <String>[
      if (l.aplicoTarifaNoche && l.tarifaNoche != null)
        'Se aplicó la tarifa noche (${formatearPesos(l.tarifaNoche!)}) por ser más económica.',
      if (l.aplicoTarifaDia && l.tarifaDia != null)
        'Se aplicó la tarifa día (${formatearPesos(l.tarifaDia!)}) por cada 24 horas.',
    ];

    return TarjetaBlanca(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (l.cerrada)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.exitoSuave,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.exito, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Salida registrada. El cupo quedó libre.',
                      style: TextStyle(
                        color: AppColors.exito,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          for (final fila in filas.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      fila.key,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textoSuave,
                      ),
                    ),
                  ),
                  Text(
                    fila.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          for (final nota in notas)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                nota,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textoSuave,
                ),
              ),
            ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.cerrada ? 'Total cobrado' : 'Total a pagar',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                formatearPesos(l.valorTotal),
                key: const Key('totalCobro'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Vehículos dentro del parqueadero; al tocar uno se calcula su cobro.
class _VehiculosAdentro extends StatelessWidget {
  const _VehiculosAdentro({
    required this.cargando,
    required this.vehiculos,
    required this.onElegir,
  });

  final bool cargando;
  final List<Liquidacion> vehiculos;
  final ValueChanged<Liquidacion>? onElegir;

  @override
  Widget build(BuildContext context) {
    return TarjetaBlanca(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehículos en el parqueadero (${vehiculos.length})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (cargando)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (vehiculos.isEmpty)
            const Text(
              'No hay vehículos registrados adentro.',
              style: TextStyle(fontSize: 13, color: AppColors.textoSuave),
            )
          else
            for (final v in vehiculos)
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    v.tipoVehiculo == TipoVehiculo.moto
                        ? Icons.two_wheeler
                        : Icons.directions_car_outlined,
                  ),
                  title: Text(
                    v.placa,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Desde ${formatearFechaHora(v.ingresoEn)} · ${v.tiempoTexto}',
                  ),
                  trailing: Text(formatearPesos(v.valorTotal)),
                  onTap: onElegir == null ? null : () => onElegir!(v),
                ),
              ),
        ],
      ),
    );
  }
}
