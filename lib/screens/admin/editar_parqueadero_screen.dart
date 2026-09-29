import 'package:flutter/material.dart';

import '../../models/parqueadero.dart';
import '../../services/api_service.dart';

/// HU-19: el administrador modifica la información de su parqueadero.
///
/// Los cambios quedan registrados en el historial de trazabilidad, que se
/// puede consultar desde el botón del AppBar.
class EditarParqueaderoScreen extends StatefulWidget {
  const EditarParqueaderoScreen({
    super.key,
    required this.parqueadero,
    this.apiService,
  });

  final Parqueadero parqueadero;

  /// Permite inyectar un servicio falso en las pruebas.
  final ApiService? apiService;

  @override
  State<EditarParqueaderoScreen> createState() =>
      _EditarParqueaderoScreenState();
}

class _EditarParqueaderoScreenState extends State<EditarParqueaderoScreen> {
  final _formKey = GlobalKey<FormState>();

  late final ApiService _apiService = widget.apiService ?? ApiService();

  late final _nombreCtrl = TextEditingController(
    text: widget.parqueadero.nombre,
  );
  late final _ubicacionCtrl = TextEditingController(
    text: widget.parqueadero.ubicacion,
  );
  late final _direccionCtrl = TextEditingController(
    text: widget.parqueadero.direccion,
  );
  late final _propietarioCtrl = TextEditingController(
    text: widget.parqueadero.nombrePropietario,
  );
  late final _capacidadCtrl = TextEditingController(
    text: widget.parqueadero.capacidadTotal?.toString() ?? '',
  );
  late final _tarifaCtrl = TextEditingController(
    text: widget.parqueadero.tarifa?.toString() ?? '',
  );
  late final _horaInicioCtrl = TextEditingController(
    text: widget.parqueadero.horaInicio ?? '',
  );
  late final _horaFinCtrl = TextEditingController(
    text: widget.parqueadero.horaFin ?? '',
  );

  bool _guardando = false;
  String? _errorMensaje;

  static final _formatoHora = RegExp(r'^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$');

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ubicacionCtrl.dispose();
    _direccionCtrl.dispose();
    _propietarioCtrl.dispose();
    _capacidadCtrl.dispose();
    _tarifaCtrl.dispose();
    _horaInicioCtrl.dispose();
    _horaFinCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _errorMensaje = null;
    });

    // Los nombres de estas claves son los que espera ParqueaderoActualizarDto
    // en el backend, que no son los mismos que los de la entidad: "capacidad"
    // (no "capacidadTotal") y "horaFinal" (no "horaFin"). Un campo vacío se
    // envía como null, para que el backend lo interprete como "no cambiar".
    final campos = {
      'nombre': _nuloSiVacio(_nombreCtrl.text),
      'direccion': _nuloSiVacio(_direccionCtrl.text),
      'ubicacion': _nuloSiVacio(_ubicacionCtrl.text),
      'nombrePropietario': _nuloSiVacio(_propietarioCtrl.text),
      'capacidad': int.tryParse(_capacidadCtrl.text),
      'tarifa': double.tryParse(_tarifaCtrl.text),
      'horaInicio': _nuloSiVacio(_horaInicioCtrl.text),
      'horaFinal': _nuloSiVacio(_horaFinCtrl.text),
    };

    final resultado = await _apiService.actualizarParqueadero(
      widget.parqueadero.id,
      campos,
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (resultado['success'] == true) {
      final cambios = resultado['data'] is List
          ? (resultado['data'] as List).length
          : 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cambios == 0
                ? 'No hubo cambios que guardar'
                : 'Parqueadero actualizado ($cambios cambios registrados)',
          ),
        ),
      );
    } else {
      setState(() => _errorMensaje = resultado['error']?.toString());
    }
  }

  String? _nuloSiVacio(String texto) {
    final limpio = texto.trim();
    return limpio.isEmpty ? null : limpio;
  }

  void _verHistorial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistorialParqueaderoScreen(
          parqueaderoId: widget.parqueadero.id,
          apiService: widget.apiService,
        ),
      ),
    );
  }

  String? _validarEnteroNoNegativo(String? valor) {
    if (valor == null || valor.isEmpty) return null;
    final numero = int.tryParse(valor);
    if (numero == null) return 'Debe ser un número';
    if (numero < 0) return 'No puede ser negativo';
    return null;
  }

  String? _validarDecimalNoNegativo(String? valor) {
    if (valor == null || valor.isEmpty) return null;
    final numero = double.tryParse(valor);
    if (numero == null) return 'Debe ser un número';
    if (numero < 0) return 'No puede ser negativo';
    return null;
  }

  String? _validarHora(String? valor) {
    if (valor == null || valor.isEmpty) return null;
    if (!_formatoHora.hasMatch(valor)) return 'Formato esperado: HH:mm';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar parqueadero'),
        actions: [
          IconButton(
            onPressed: _verHistorial,
            icon: const Icon(Icons.history),
            tooltip: 'Ver historial de cambios',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _ubicacionCtrl,
                decoration: const InputDecoration(labelText: 'Ubicación'),
              ),
              TextFormField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              TextFormField(
                controller: _propietarioCtrl,
                decoration: const InputDecoration(labelText: 'Propietario'),
              ),
              TextFormField(
                controller: _capacidadCtrl,
                decoration: const InputDecoration(labelText: 'Capacidad total'),
                keyboardType: TextInputType.number,
                validator: _validarEnteroNoNegativo,
              ),
              TextFormField(
                controller: _tarifaCtrl,
                decoration: const InputDecoration(labelText: 'Tarifa'),
                keyboardType: TextInputType.number,
                validator: _validarDecimalNoNegativo,
              ),
              TextFormField(
                controller: _horaInicioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Hora de inicio',
                  hintText: 'HH:mm',
                ),
                validator: _validarHora,
              ),
              TextFormField(
                controller: _horaFinCtrl,
                decoration: const InputDecoration(
                  labelText: 'Hora de fin',
                  hintText: 'HH:mm',
                ),
                validator: _validarHora,
              ),
              const SizedBox(height: 20),
              if (_errorMensaje != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMensaje!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              _guardando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _guardar,
                      child: const Text('Guardar cambios'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// HU-19: consulta del historial de trazabilidad de un parqueadero.
class HistorialParqueaderoScreen extends StatefulWidget {
  const HistorialParqueaderoScreen({
    super.key,
    required this.parqueaderoId,
    this.apiService,
  });

  final int parqueaderoId;
  final ApiService? apiService;

  @override
  State<HistorialParqueaderoScreen> createState() =>
      _HistorialParqueaderoScreenState();
}

class _HistorialParqueaderoScreenState
    extends State<HistorialParqueaderoScreen> {
  late final ApiService _apiService = widget.apiService ?? ApiService();

  List<CambioParqueadero> _cambios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final datos = await _apiService.obtenerHistorial(widget.parqueaderoId);
    if (!mounted) return;
    setState(() {
      _cambios = datos
          .whereType<Map<String, dynamic>>()
          .map(CambioParqueadero.fromJson)
          .toList();
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de cambios')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _cambios.isEmpty
          ? const Center(child: Text('Sin cambios registrados'))
          : ListView.builder(
              itemCount: _cambios.length,
              itemBuilder: (context, i) {
                final cambio = _cambios[i];
                return ListTile(
                  title: Text(cambio.campo),
                  subtitle: Text(
                    '${cambio.valorAnterior ?? "(vacío)"} → ${cambio.valorNuevo ?? "(vacío)"}',
                  ),
                  trailing: Text(
                    cambio.fecha?.split('T').first ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
    );
  }
}
