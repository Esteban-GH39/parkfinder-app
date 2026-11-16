import 'package:flutter/material.dart';

import '../../models/estadia.dart';
import '../../models/parqueadero.dart';
import '../../services/comprobante_service.dart';
import '../../services/estadia_service.dart';
import '../../services/parqueadero_service.dart';
import '../../services/reserva_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets_comunes.dart';
import 'codigo_reserva_screen.dart';
import 'ingreso_vehiculo_screen.dart';
import 'salida_vehiculo_screen.dart';

class GestionCuposParqueaderoScreen extends StatefulWidget {
  final Parqueadero parqueadero;

  /// Permite inyectar servicios falsos en las pruebas.
  final ParqueaderoService? parqueaderoService;
  final ComprobanteService? comprobanteService;
  final EstadiaService? estadiaService;
  final ReservaService? reservaService;

  const GestionCuposParqueaderoScreen({
    super.key,
    required this.parqueadero,
    this.parqueaderoService,
    this.comprobanteService,
    this.estadiaService,
    this.reservaService,
  });

  @override
  State<GestionCuposParqueaderoScreen> createState() =>
      _DetalleParqueaderoScreenState();
}

class _DetalleParqueaderoScreenState
    extends State<GestionCuposParqueaderoScreen> {
  late final ParqueaderoService _parqueaderoService =
      widget.parqueaderoService ?? ParqueaderoService();

  late int _cuposDisponibles;
  late int _capacidadTotal;
  late int _capacidadMotos;
  late int _cuposMotos;
  bool _verMotos = false;
  bool _isLoading = false;

  bool get _tieneMotos => _capacidadMotos > 0;

  /// Capacidad y cupos libres del tipo de vehículo que se está gestionando.
  int get _capacidadTipo => _verMotos ? _capacidadMotos : _capacidadTotal - _capacidadMotos;
  int get _libresTipo => _verMotos ? _cuposMotos : _cuposDisponibles - _cuposMotos;

  @override
  void initState() {
    super.initState();
    _capacidadTotal = widget.parqueadero.capacidadTotal ?? 0;
    _cuposDisponibles = widget.parqueadero.cuposDisponibles;
    _capacidadMotos = widget.parqueadero.capacidadMotos;
    _cuposMotos = widget.parqueadero.cuposMotos;
  }

  // METODO PARA MODIFICAR ACTUALIZAR CUPOS DISNPONIBLES CON LA API
  Future<void> _modificarCupos(int delta) async {
    final nuevoValor = _cuposDisponibles + delta;
    final nuevosMotos = _cuposMotos + (_verMotos ? delta : 0);

    // Validación preventiva en Flutter
    if (_tieneMotos) {
      final tipo = _verMotos ? 'motos' : 'carros';
      if (_libresTipo + delta < 0) {
        _mostrarSnackBar('No hay cupos de $tipo disponibles para descontar.', isError: true);
        return;
      }
      if (_libresTipo + delta > _capacidadTipo) {
        _mostrarSnackBar(
          'Los cupos de $tipo no pueden superar su capacidad ($_capacidadTipo).',
          isError: true,
        );
        return;
      }
    } else {
      if (nuevoValor < 0) {
        _mostrarSnackBar(
          'No hay cupos disponibles para descontar.',
          isError: true,
        );
        return;
      }
      if (nuevoValor > _capacidadTotal) {
        _mostrarSnackBar(
          'La cantidad de cupos no puede superar la capacidad total ($_capacidadTotal).',
          isError: true,
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_tieneMotos) {
        await _parqueaderoService.actualizarCuposPorTipo(
          idParqueadero: widget.parqueadero.id,
          idAdmin: widget.parqueadero.fk_parqueadero_admin,
          nuevosCupos: nuevoValor,
          cuposMotos: nuevosMotos,
        );
      } else {
        await _parqueaderoService.actualizarCuposDisponibles(
          idParqueadero: widget.parqueadero.id,
          idAdmin: widget.parqueadero.fk_parqueadero_admin,
          nuevosCupos: nuevoValor,
        );
      }

      setState(() {
        _cuposDisponibles = nuevoValor;
        _cuposMotos = nuevosMotos;
      });

      _mostrarSnackBar('Cupos actualizados correctamente.');
    } catch (e) {
      // Muestra la excepción lanzada desde Quarkus en el SnackBar
      _mostrarSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ABRE LA PANTALLA DE CÓDIGO DE RESERVA Y ACTUALIZA LOS CUPOS AL VOLVER
  Future<void> _abrirCodigoReserva() async {
    final nuevosCupos = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => CodigoReservaScreen(
          parqueadero: widget.parqueadero,
          cuposDisponibles: _cuposDisponibles,
          parqueaderoService: widget.parqueaderoService,
          comprobanteService: widget.comprobanteService,
          estadiaService: widget.estadiaService,
          reservaService: widget.reservaService,
        ),
      ),
    );

    if (nuevosCupos != null && mounted) {
      setState(() => _cuposDisponibles = nuevosCupos);
    }
  }

  // ABRE EL INGRESO DIRECTO POR PLACA. El backend ya descontó el cupo; aquí solo se refleja.
  Future<void> _abrirIngreso() async {
    final estadia = await Navigator.push<Estadia>(
      context,
      MaterialPageRoute(
        builder: (context) => IngresoVehiculoScreen(
          parqueadero: widget.parqueadero,
          tipoInicial: _verMotos ? TipoVehiculo.moto : TipoVehiculo.carro,
          estadiaService: widget.estadiaService,
        ),
      ),
    );
    if (estadia == null || !mounted) return;

    setState(() {
      _cuposDisponibles = (_cuposDisponibles - 1).clamp(0, _capacidadTotal);
      if (estadia.tipoVehiculo == TipoVehiculo.moto) {
        _cuposMotos = (_cuposMotos - 1).clamp(0, _capacidadMotos);
      }
    });
    _mostrarSnackBar(
      'Ingreso registrado: ${estadia.placa} a las ${_hora(estadia.ingresoEn)}.',
    );
  }

  // ABRE LA SALIDA POR PLACA CON EL COBRO. El backend ya liberó el cupo; aquí solo se refleja.
  Future<void> _abrirSalida() async {
    final liquidacion = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (context) => SalidaVehiculoScreen(
          parqueadero: widget.parqueadero,
          estadiaService: widget.estadiaService,
        ),
      ),
    );
    if (liquidacion is! Liquidacion || !liquidacion.cerrada || !mounted) return;

    // Igual que el backend: un cupo más del tipo, sin pasar de su capacidad
    setState(() {
      var motos = _cuposMotos;
      var carros = (_cuposDisponibles - _cuposMotos).clamp(0, _capacidadTotal);
      if (liquidacion.tipoVehiculo == TipoVehiculo.moto) {
        motos = (motos + 1).clamp(0, _capacidadMotos);
      } else {
        carros = (carros + 1).clamp(0, _capacidadTotal - _capacidadMotos);
      }
      _cuposMotos = motos;
      _cuposDisponibles = carros + motos;
    });
    _mostrarSnackBar(
      'Cupo liberado: ${liquidacion.placa} pagó ${formatearPesos(liquidacion.valorTotal)}.',
    );
  }

  String _hora(DateTime? fecha) => fecha == null
      ? '-'
      : '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

  void _mostrarSnackBar(String mensaje, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? AppColors.error : AppColors.exito,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final capacidad = _tieneMotos ? _capacidadTipo : _capacidadTotal;
    final libres = _tieneMotos ? _libresTipo : _cuposDisponibles;
    final ocupados = (capacidad - libres).clamp(0, capacidad);
    final secundario = ElevatedButton.styleFrom(
      backgroundColor: AppColors.chip,
      foregroundColor: AppColors.texto,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de cupos'), centerTitle: true),
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
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.acentoSuave,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.local_parking,
                          color: AppColors.acento,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Parqueadero',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textoSuave,
                              ),
                            ),
                            Text(
                              widget.parqueadero.nombre.isNotEmpty
                                  ? widget.parqueadero.nombre
                                  : 'Parqueadero ${widget.parqueadero.id}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_tieneMotos) ...[
                    const SizedBox(height: 18),
                    SegmentedButton<bool>(
                      key: const Key('tipoVehiculoGestion'),
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Carros'),
                          icon: Icon(Icons.directions_car_outlined),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Motos'),
                          icon: Icon(Icons.two_wheeler),
                        ),
                      ],
                      selected: {_verMotos},
                      onSelectionChanged: (v) =>
                          setState(() => _verMotos = v.first),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _Dato(
                          valor: '$libres',
                          etiqueta: _tieneMotos
                              ? (_verMotos ? 'Cupos de moto libres' : 'Cupos de carro libres')
                              : 'Cupos disponibles',
                          color: libres == 0 ? AppColors.error : AppColors.texto,
                        ),
                      ),
                      Expanded(
                        child: _Dato(
                          valor: '$capacidad',
                          etiqueta: _tieneMotos ? 'Capacidad' : 'Capacidad total',
                          color: AppColors.textoSuave,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: capacidad == 0 ? 0 : ocupados / capacidad,
                      minHeight: 8,
                      backgroundColor: AppColors.chip,
                      color: libres == 0
                          ? AppColors.error
                          : AppColors.acento,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
            // Valida el comprobante y descuenta un cupo
            ElevatedButton(
              onPressed: _isLoading ? null : _abrirCodigoReserva,
              child: const Text('Código de reserva'),
            ),
            const SizedBox(height: 12),
            // Registra la placa y la hora de ingreso, y descuenta un cupo
            ElevatedButton(
              style: secundario,
              onPressed: _isLoading ? null : _abrirIngreso,
              child: const Text('Ingreso directo'),
            ),
            const SizedBox(height: 12),
            // Calcula el cobro por placa y libera el cupo
            ElevatedButton(
              style: secundario,
              onPressed: _isLoading ? null : _abrirSalida,
              child: const Text('Liberar cupo'),
            ),
            const SizedBox(height: 20),
            // Corrección manual de los cupos, sin registrar placa
            Text(
              'Ajuste manual de cupos',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textoSuave,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _modificarCupos(-1),
                    child: Text(_tieneMotos ? '-1 ${_verMotos ? 'moto' : 'carro'}' : '-1 cupo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _modificarCupos(1),
                    child: Text(_tieneMotos ? '+1 ${_verMotos ? 'moto' : 'carro'}' : '+1 cupo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.valor,
    required this.etiqueta,
    required this.color,
  });
  final String valor;
  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        valor,
        style: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w700,
          height: 1.1,
          color: color,
        ),
      ),
      Text(
        etiqueta,
        style: const TextStyle(fontSize: 12.5, color: AppColors.textoSuave),
      ),
    ],
  );
}
