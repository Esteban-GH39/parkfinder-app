import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/comprobante.dart';
import '../../models/parqueadero.dart';
import '../../services/comprobante_service.dart';
import '../../services/parqueadero_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets_comunes.dart';

class CodigoReservaScreen extends StatefulWidget {
  final Parqueadero parqueadero;
  final int cuposDisponibles;

  /// Permite inyectar servicios falsos en las pruebas.
  final ParqueaderoService? parqueaderoService;
  final ComprobanteService? comprobanteService;

  const CodigoReservaScreen({
    super.key,
    required this.parqueadero,
    required this.cuposDisponibles,
    this.parqueaderoService,
    this.comprobanteService,
  });

  @override
  State<CodigoReservaScreen> createState() => _CodigoReservaScreenState();
}

class _CodigoReservaScreenState extends State<CodigoReservaScreen> {
  late final ComprobanteService _comprobanteService =
      widget.comprobanteService ?? ComprobanteService();
  late final ParqueaderoService _parqueaderoService =
      widget.parqueaderoService ?? ParqueaderoService();
  final TextEditingController _idComprobanteController =
      TextEditingController();

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
    super.dispose();
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
    final nuevoValor = _cuposDisponibles - 1;
    if (nuevoValor < 0) {
      _mostrarSnackBar(
        'No hay cupos disponibles para descontar.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _parqueaderoService.actualizarCuposDisponibles(
        idParqueadero: widget.parqueadero.id,
        idAdmin: widget.parqueadero.fk_parqueadero_admin,
        nuevosCupos: nuevoValor,
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
                      hintText: 'Id del comprobante de pago',
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

  /// Datos del comprobante consultado
  Widget _buildDetalleComprobante(Comprobante c) {
    final filas = {
      'Id comprobante': '${c.id}',
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
