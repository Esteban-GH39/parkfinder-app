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
  late final _zonaCtrl = TextEditingController(text: widget.parqueadero.zona);
  late final _direccionCtrl = TextEditingController(
    text: widget.parqueadero.direccion,
  );
  late final _representanteCtrl = TextEditingController(
    text: widget.parqueadero.representante,
  );
  late final _capacidadCtrl = TextEditingController(
    text: widget.parqueadero.capacidadTotal?.toString() ?? '',
  );
  late final _ocupadosCtrl = TextEditingController(
    text: widget.parqueadero.cuposOcupados?.toString() ?? '',
  );
  late final _tarifaHoraCtrl = TextEditingController(
    text: widget.parqueadero.tarifaHora?.toString() ?? '',
  );
  late final _tarifaDiaCtrl = TextEditingController(
    text: widget.parqueadero.tarifaDia?.toString() ?? '',
  );

  bool _guardando = false;
  String? _errorMensaje;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _zonaCtrl.dispose();
    _direccionCtrl.dispose();
    _representanteCtrl.dispose();
    _capacidadCtrl.dispose();
    _ocupadosCtrl.dispose();
    _tarifaHoraCtrl.dispose();
    _tarifaDiaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _errorMensaje = null;
    });

    final campos = {
      'nombre': _nombreCtrl.text.trim(),
      'zona': _zonaCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
      'representante': _representanteCtrl.text.trim(),
      'capacidadTotal': int.tryParse(_capacidadCtrl.text),
      'cuposOcupados': int.tryParse(_ocupadosCtrl.text),
      'tarifaHora': double.tryParse(_tarifaHoraCtrl.text),
      'tarifaDia': double.tryParse(_tarifaDiaCtrl.text),
    };

    final resultado = await _apiService.actualizarParqueadero(
      widget.parqueadero.id,
      campos,
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (resultado['success'] == true) {
      final cambios = resultado['data']?['cambiosRegistrados'];
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

  /// La ocupación nunca puede superar la capacidad: la misma regla que valida
  /// el backend, adelantada acá para avisar antes de enviar.
  String? _validarOcupados(String? valor) {
    if (valor == null || valor.isEmpty) return null;
    final ocupados = int.tryParse(valor);
    if (ocupados == null) return 'Debe ser un número';
    if (ocupados < 0) return 'No puede ser negativo';

    final capacidad = int.tryParse(_capacidadCtrl.text);
    if (capacidad != null && ocupados > capacidad) {
      return 'No puede superar la capacidad ($capacidad)';
    }
    return null;
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
                controller: _zonaCtrl,
                decoration: const InputDecoration(labelText: 'Zona'),
              ),
              TextFormField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              TextFormField(
                controller: _representanteCtrl,
                decoration: const InputDecoration(labelText: 'Representante'),
              ),
              TextFormField(
                controller: _capacidadCtrl,
                decoration: const InputDecoration(labelText: 'Capacidad total'),
                keyboardType: TextInputType.number,
                validator: _validarEnteroNoNegativo,
              ),
              TextFormField(
                controller: _ocupadosCtrl,
                decoration: const InputDecoration(labelText: 'Cupos ocupados'),
                keyboardType: TextInputType.number,
                validator: _validarOcupados,
              ),
              TextFormField(
                controller: _tarifaHoraCtrl,
                decoration: const InputDecoration(labelText: 'Tarifa por hora'),
                keyboardType: TextInputType.number,
                validator: _validarDecimalNoNegativo,
              ),
              TextFormField(
                controller: _tarifaDiaCtrl,
                decoration: const InputDecoration(labelText: 'Tarifa por día'),
                keyboardType: TextInputType.number,
                validator: _validarDecimalNoNegativo,
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
