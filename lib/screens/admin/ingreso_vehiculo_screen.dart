import 'package:flutter/material.dart';

import '../../models/estadia.dart';
import '../../models/parqueadero.dart';
import '../../services/estadia_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets_comunes.dart';
import 'campo_placa.dart';

/// Ingreso directo: el administrador digita la placa y el sistema guarda la
/// fecha y hora de ingreso y descuenta un cupo. Cierra devolviendo la [Estadia].
class IngresoVehiculoScreen extends StatefulWidget {
  const IngresoVehiculoScreen({
    super.key,
    required this.parqueadero,
    this.tipoInicial = TipoVehiculo.carro,
    this.estadiaService,
  });

  final Parqueadero parqueadero;
  final TipoVehiculo tipoInicial;

  /// Permite inyectar un servicio falso en las pruebas.
  final EstadiaService? estadiaService;

  @override
  State<IngresoVehiculoScreen> createState() => _IngresoVehiculoScreenState();
}

class _IngresoVehiculoScreenState extends State<IngresoVehiculoScreen> {
  late final EstadiaService _servicio =
      widget.estadiaService ?? EstadiaService();
  final _placaCtrl = TextEditingController();
  late TipoVehiculo _tipo = widget.parqueadero.tieneMotos
      ? widget.tipoInicial
      : TipoVehiculo.carro;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _placaCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!placaValida(_placaCtrl.text)) {
      setState(() => _error = mensajePlacaInvalida);
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final estadia = await _servicio.ingresoDirecto(
        parqueaderoId: widget.parqueadero.id,
        adminId: widget.parqueadero.fk_parqueadero_admin,
        placa: normalizarPlaca(_placaCtrl.text),
        tipo: _tipo,
      );
      if (!mounted) return;
      Navigator.pop(context, estadia);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingreso directo'), centerTitle: true),
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
                    'Digita la placa del vehículo que ingresa. La fecha y la '
                    'hora de ingreso se registran automáticamente.',
                    style: TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                  if (widget.parqueadero.tieneMotos) ...[
                    const SizedBox(height: 16),
                    SelectorTipoVehiculo(
                      valor: _tipo,
                      onChanged: _guardando
                          ? null
                          : (t) => setState(() => _tipo = t),
                    ),
                  ],
                  const SizedBox(height: 16),
                  CampoPlaca(
                    key: const Key('placaIngreso'),
                    controller: _placaCtrl,
                    tipo: _tipo,
                    enabled: !_guardando,
                    onSubmitted: (_) => _registrar(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    AvisoError(texto: _error!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _guardando ? null : _registrar,
              child: _guardando
                  ? const CargandoEnBoton()
                  : const Text('Registrar ingreso'),
            ),
          ],
        ),
      ),
    );
  }
}
