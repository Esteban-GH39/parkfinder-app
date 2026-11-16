import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/comprobante.dart';
import '../../models/estadia.dart';
import '../../models/parqueadero.dart';
import '../../services/comprobante_service.dart';
import '../../services/estadia_service.dart';
import '../../services/parqueadero_service.dart';
import '../../services/reserva_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets_comunes.dart';
import 'campo_placa.dart';

class CodigoReservaScreen extends StatefulWidget {
  final Parqueadero parqueadero;
  final int cuposDisponibles;

  /// Permite inyectar servicios falsos en las pruebas.
  /// [parqueaderoService] ya no se usa aquí: el backend descuenta el cupo al
  /// registrar la placa. Se conserva para no romper a quien lo pasa.
  final ParqueaderoService? parqueaderoService;
  final ComprobanteService? comprobanteService;
  final ReservaService? reservaService;
  final EstadiaService? estadiaService;

  const CodigoReservaScreen({
    super.key,
    required this.parqueadero,
    required this.cuposDisponibles,
    this.parqueaderoService,
    this.comprobanteService,
    this.reservaService,
    this.estadiaService,
  });

  @override
  State<CodigoReservaScreen> createState() => _CodigoReservaScreenState();
}

class _CodigoReservaScreenState extends State<CodigoReservaScreen> {
  late final ComprobanteService _comprobanteService =
      widget.comprobanteService ?? ComprobanteService();
  late final ReservaService _reservaService =
      widget.reservaService ?? ReservaService();
  late final EstadiaService _estadiaService =
      widget.estadiaService ?? EstadiaService();
  final TextEditingController _idComprobanteController =
      TextEditingController();

  /// Un campo de placa por cada vehículo que puede ingresar con el comprobante.
  final List<_PlacaVehiculo> _placas = [];

  /// Resumen de la reserva (cuántos carros y motos), si se pudo consultar.
  String? _resumenReserva;

  late int _cuposDisponibles;
  Comprobante? _comprobante;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cuposDisponibles = widget.cuposDisponibles;
  }

  @override
  void dispose() {
    _idComprobanteController.dispose();
    _limpiarPlacas();
    super.dispose();
  }

  void _limpiarPlacas() {
    for (final p in _placas) {
      p.controller.dispose();
    }
    _placas.clear();
    _resumenReserva = null;
  }

  // PREPARA LOS CAMPOS DE PLACA: uno por cada carro y moto de la reserva.
  // Sin reserva (comprobante viejo) o si no se puede consultar, un solo campo.
  Future<void> _prepararPlacas(Comprobante comprobante) async {
    final reservaId = comprobante.reservaId;
    if (reservaId != null) {
      final resultado = await _reservaService.obtener(reservaId);
      final data = resultado['data'];
      if (resultado['success'] == true && data is Map) {
        final total = (data['cantidad'] as num?)?.toInt() ?? 1;
        final motos = (data['cantidadMotos'] as num?)?.toInt() ?? 0;
        final carros =
            (data['cantidadCarros'] as num?)?.toInt() ?? (total - motos);
        for (var i = 0; i < carros; i++) {
          _placas.add(
            _PlacaVehiculo(TipoVehiculo.carro, 'Placa carro ${i + 1}'),
          );
        }
        for (var i = 0; i < motos; i++) {
          _placas.add(_PlacaVehiculo(TipoVehiculo.moto, 'Placa moto ${i + 1}'));
        }
        final partes = [
          if (carros > 0) '$carros carro(s)',
          if (motos > 0) '$motos moto(s)',
        ];
        _resumenReserva = 'Reserva #$reservaId: ${partes.join(' y ')}.';
        if (_placas.isNotEmpty) return;
      }
    }
    _placas.add(
      _PlacaVehiculo(
        TipoVehiculo.carro,
        'Placa del vehículo',
        tipoEditable: true,
      ),
    );
  }

  /// Placas digitadas (las vacías se ignoran). Null si alguna es inválida o no hay ninguna.
  List<({String placa, TipoVehiculo tipo})>? _vehiculosDigitados() {
    final vehiculos = <({String placa, TipoVehiculo tipo})>[];
    for (final p in _placas) {
      final texto = p.controller.text.trim();
      if (texto.isEmpty) continue;
      if (!placaValida(texto)) {
        _mostrarSnackBar(mensajePlacaInvalida, isError: true);
        return null;
      }
      vehiculos.add((placa: normalizarPlaca(texto), tipo: p.tipo));
    }
    if (vehiculos.isEmpty) {
      _mostrarSnackBar('Digita la placa del vehículo.', isError: true);
      return null;
    }
    return vehiculos;
  }

  // METODO PARA CONSULTAR EL COMPROBANTE POR EL ID INGRESADO
  Future<void> _validarComprobante() async {
    final id = int.tryParse(_idComprobanteController.text.trim());
    if (id == null) {
      _mostrarSnackBar('Ingrese un id de comprobante válido.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _comprobante = null;
      _error = null;
      _limpiarPlacas();
    });

    try {
      final comprobante = await _comprobanteService.obtenerPorId(id);

      // Solo se muestran comprobantes del parqueadero seleccionado
      if (comprobante.fkComprobanteParqueadero != widget.parqueadero.id) {
        setState(
          () => _error = 'El comprobante $id no pertenece a este parqueadero.',
        );
        return;
      }

      // Solo se muestran comprobantes con pago APROBADO
      final estado = comprobante.estadoTransaccion?.trim().toUpperCase();
      if (estado != 'APROBADO') {
        final mensaje = switch (estado) {
          'PENDIENTE' => 'El pago del comprobante $id aún está pendiente.',
          'RECHAZADO' => 'El pago del comprobante $id fue rechazado.',
          _ =>
            'El comprobante $id no está aprobado (estado: ${comprobante.estadoTransaccion ?? 'sin estado'}).',
        };
        setState(() => _error = mensaje);
        return;
      }

      await _prepararPlacas(comprobante);
      if (!mounted) return;
      setState(() => _comprobante = comprobante);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // METODO PARA VALIDAR LA RESERVA Y DESCONTAR UN CUPO DISPONIBLE
  Future<void> _validarReserva() async {
    final comprobante = _comprobante;
    if (comprobante == null) {
      _mostrarSnackBar('Primero valide el comprobante de pago.', isError: true);
      return;
    }
    // Comprobante de una reserva con pago: se valida el código y se registran las
    // placas con la hora de ingreso. Sus cupos ya se descontaron al reservar, así
    // que no se vuelve a descontar nada.
    final reservaId = comprobante.reservaId;
    if (reservaId != null) {
      final vehiculos = _vehiculosDigitados();
      if (vehiculos == null) return;
      setState(() => _isLoading = true);
      try {
        await _estadiaService.ingresoConReserva(
          reservaId: reservaId,
          parqueaderoId: widget.parqueadero.id,
          adminId: widget.parqueadero.fk_parqueadero_admin,
          vehiculos: vehiculos,
        );
        if (!mounted) return;
        final placas = vehiculos.map((v) => v.placa).join(', ');
        _mostrarSnackBar('Código validado. Ingreso registrado: $placas.');
        Navigator.pop(context, _cuposDisponibles);
      } catch (e) {
        _mostrarSnackBar(
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    final nuevoValor = _cuposDisponibles - 1;
    if (nuevoValor < 0) {
      _mostrarSnackBar(
        'No hay cupos disponibles para descontar.',
        isError: true,
      );
      return;
    }

    final vehiculos = _vehiculosDigitados();
    if (vehiculos == null) return;

    setState(() => _isLoading = true);

    try {
      // Comprobante sin reserva: el backend registra la placa y descuenta el cupo
      await _estadiaService.ingresoDirecto(
        parqueaderoId: widget.parqueadero.id,
        adminId: widget.parqueadero.fk_parqueadero_admin,
        placa: vehiculos.first.placa,
        tipo: vehiculos.first.tipo,
      );

      setState(() => _cuposDisponibles = nuevoValor);
      _mostrarSnackBar('Reserva validada. Cupos disponibles: $nuevoValor');

      if (mounted) Navigator.pop(context, _cuposDisponibles);
    } catch (e) {
      _mostrarSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
    return Scaffold(
      appBar: AppBar(title: const Text('Código de reserva'), centerTitle: true),
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
                  const SizedBox(height: 14),
                  TextField(
                    controller: _idComprobanteController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'Ingresa el código de reserva',
                      prefixIcon: Icon(Icons.receipt_long_outlined),
                    ),
                    onSubmitted: (_) => _validarComprobante(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    AvisoError(texto: _error!),
                  ],
                  const SizedBox(height: 18),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _validarComprobante,
                          child: const Text('Validar comprobante'),
                        ),
                ],
              ),
            ),
            if (_comprobante != null) ...[
              const SizedBox(height: 16),
              _buildDetalleComprobante(_comprobante!),
              const SizedBox(height: 16),
              _buildPlacas(),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading || _comprobante == null
                  ? null
                  : _validarReserva,
              child: const Text('Validar reserva'),
            ),
          ],
        ),
      ),
    );
  }

  /// Campos para digitar la placa de cada vehículo que ingresa
  Widget _buildPlacas() {
    final ayuda = [
      ?_resumenReserva,
      'La hora de ingreso se registra automáticamente.',
      if (_placas.length > 1) 'Deja vacía la placa del vehículo que no llegó.',
    ].join(' ');
    return TarjetaBlanca(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _placas.length > 1
                ? 'Placas de los vehículos'
                : 'Placa del vehículo',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            ayuda,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textoSuave),
          ),
          for (var i = 0; i < _placas.length; i++) ...[
            const SizedBox(height: 14),
            if (_placas[i].tipoEditable && widget.parqueadero.tieneMotos) ...[
              SelectorTipoVehiculo(
                valor: _placas[i].tipo,
                onChanged: _isLoading
                    ? null
                    : (t) => setState(() => _placas[i].tipo = t),
              ),
              const SizedBox(height: 10),
            ],
            CampoPlaca(
              key: Key('placa_$i'),
              controller: _placas[i].controller,
              etiqueta: _placas[i].etiqueta,
              tipo: _placas[i].tipo,
              enabled: !_isLoading,
            ),
          ],
        ],
      ),
    );
  }

  /// Datos del comprobante consultado
  Widget _buildDetalleComprobante(Comprobante c) {
    final filas = {
      'Código': '${c.id}',
      'Fecha generado': c.fechaGenerado ?? '-',
      'Valor pago': c.valorPago != null
          ? '\$${c.valorPago!.toStringAsFixed(0)}'
          : '-',
      'Medio de pago': c.medioPago ?? '-',
      'Estado transacción': c.estadoTransaccion ?? '-',
      'Id cliente': '${c.fkComprobanteCliente ?? '-'}',
      'Id parqueadero': '${c.fkComprobanteParqueadero ?? '-'}',
    };
    return TarjetaBlanca(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      child: Column(
        children: [
          for (final fila in filas.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
        ],
      ),
    );
  }
}

/// Un campo de placa y el tipo de vehículo al que corresponde.
class _PlacaVehiculo {
  _PlacaVehiculo(this.tipo, this.etiqueta, {this.tipoEditable = false});

  TipoVehiculo tipo;
  final String etiqueta;

  /// Solo sin reserva: el administrador elige si es carro o moto.
  final bool tipoEditable;
  final TextEditingController controller = TextEditingController();
}
