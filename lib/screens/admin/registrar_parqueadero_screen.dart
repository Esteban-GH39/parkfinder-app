import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/parqueadero.dart';
import '../../services/api_service.dart';

/// HU-18: el administrador registra un nuevo parqueadero.
///
/// Al registrar con éxito muestra un mensaje de confirmación y cierra la
/// pantalla devolviendo `true`, para que la pantalla que la abrió recargue
/// la lista.
class RegistroParqueaderoScreen extends StatefulWidget {
  const RegistroParqueaderoScreen({super.key, this.apiService});

  /// Permite inyectar un servicio falso en las pruebas.
  final ApiService? apiService;

  @override
  State<RegistroParqueaderoScreen> createState() =>
      _RegistroParqueaderoScreenState();
}

class _RegistroParqueaderoScreenState extends State<RegistroParqueaderoScreen> {
  /// Únicas zonas válidas para el registro
  static const List<String> _localidades = [
    'Usaquén',
    'Chapinero',
    'Santa Fe',
    'San Cristóbal',
    'Usme',
    'Tunjuelito',
    'Bosa',
    'Kennedy',
    'Fontibón',
    'Engativá',
    'Suba',
    'Barrios Unidos',
    'Teusaquillo',
    'Los Mártires',
    'Antonio Nariño',
    'Puente Aranda',
    'La Candelaria',
    'Rafael Uribe Uribe',
    'Ciudad Bolívar',
  ];

  final _formKey = GlobalKey<FormState>();

  late final ApiService _apiService = widget.apiService ?? ApiService();

  final _nombreCtrl = TextEditingController();
  final _zonaCtrl = TextEditingController();
  final _zonaFocus = FocusNode();
  final _direccionCtrl = TextEditingController();
  final _representanteCtrl = TextEditingController();
  final _capacidadCtrl = TextEditingController();
  final _tarifaHoraCtrl = TextEditingController();
  final _tarifaDiaCtrl = TextEditingController();
  final _tarifaNocheCtrl = TextEditingController();
  final _horaInicioCtrl = TextEditingController();
  final _horaFinalCtrl = TextEditingController();

  bool _guardando = false;
  String? _errorMensaje;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _zonaCtrl.dispose();
    _zonaFocus.dispose();
    _direccionCtrl.dispose();
    _representanteCtrl.dispose();
    _capacidadCtrl.dispose();
    _tarifaHoraCtrl.dispose();
    _tarifaDiaCtrl.dispose();
    _tarifaNocheCtrl.dispose();
    _horaInicioCtrl.dispose();
    _horaFinalCtrl.dispose();
    super.dispose();
  }



  /// Comparar usaquen con Usaquén.
  String _normalizar(String texto) {
    const conTilde = 'áéíóúüÁÉÍÓÚÜ';
    const sinTilde = 'aeiouuaeiouu';
    var resultado = texto.trim().toLowerCase();
    for (var i = 0; i < conTilde.length; i++) {
      resultado = resultado.replaceAll(conTilde[i], sinTilde[i]);
    }
    return resultado;
  }

  /// Devuelve el nombre oficial de la localidad o null si no es válida.
  String? _localidadOficial(String texto) {
    final buscada = _normalizar(texto);
    if (buscada.isEmpty) return null;
    for (final localidad in _localidades) {
      if (_normalizar(localidad) == buscada) return localidad;
    }
    return null;
  }

  String? _validarLocalidad(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Requerido';
    if (_localidadOficial(valor) == null) {
      return 'Selecciona una localidad válida de Bogotá';
    }
    return null;
  }

  // TARIFAS

  // Convierte cualquier formato numérico a double:
  // "2500", "2500.50", "2500,50", "2.500", "2,500", "2.500,50", "2,500.50".
  //
  // Regla para un solo separador que aparece una vez: si tiene exactamente
  // 3 dígitos después, se toma como separador de miles ("2.500" = 2500);
  // en otro caso es decimal ("2.5" = 2.5, "2500,50" = 2500.5).
  double? _parsearNumero(String texto) {
    final t = texto.replaceAll(RegExp(r'\s'), '');
    if (t.isEmpty || !RegExp(r'^[0-9.,]+$').hasMatch(t)) return null;

    final ultimoPunto = t.lastIndexOf('.');
    final ultimaComa = t.lastIndexOf(',');
    String normalizado;

    if (ultimoPunto != -1 && ultimaComa != -1) {
      final decimal = ultimoPunto > ultimaComa ? '.' : ',';
      final miles = decimal == '.' ? ',' : '.';
      normalizado = t.replaceAll(miles, '').replaceAll(decimal, '.');
    } else if (ultimoPunto != -1 || ultimaComa != -1) {
      final separador = ultimoPunto != -1 ? '.' : ',';
      final partes = t.split(separador);
      final esMiles =
          partes.length > 2 ||
              (partes.last.length == 3 &&
                  partes.first.isNotEmpty &&
                  partes.first.length <= 3 &&
                  partes.first != '0');
      if (esMiles) {
        normalizado = partes.join();
      } else if (partes.last.isEmpty) {
        normalizado = partes.first;
      } else {
        normalizado = '${partes.first}.${partes.last}';
      }
    } else {
      normalizado = t;
    }

    return double.tryParse(normalizado);
  }

  String? _validarTarifa(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Requerido';
    final numero = _parsearNumero(valor);
    if (numero == null) return 'Debe ser un número válido';
    if (numero < 0) return 'No puede ser negativo';
    return null;
  }

  //REGISTRO

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _errorMensaje = null;
    });

    final parqueadero = Parqueadero(
      id: 0, // el backend asigna el id
      nombre: _nombreCtrl.text.trim(),
      zona: _localidadOficial(_zonaCtrl.text) ?? _zonaCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
      representante: _representanteCtrl.text.trim(),
      capacidadTotal: int.tryParse(_capacidadCtrl.text.trim()),
      tarifaHora: _parsearNumero(_tarifaHoraCtrl.text),
      tarifaDia: _parsearNumero(_tarifaDiaCtrl.text),
      tarifaNoche: _parsearNumero(_tarifaNocheCtrl.text),
      horaInicio: _horaInicioCtrl.text,
      horaFinal: _horaFinalCtrl.text,
    );

    final resultado = await _apiService.registrarParqueadero(parqueadero);

    if (!mounted) return;
    setState(() => _guardando = false);

    if (resultado['success'] == true) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          content: const Text(
            'Registraste tu parqueadero con éxito!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      setState(() => _errorMensaje = resultado['error']?.toString());
    }
  }

  // Abre el selector de hora y escribe el resultado como "HH:mm", que es el
  // formato que espera el LocalTime del backend.
  Future<void> _seleccionarHora(TextEditingController ctrl) async {
    TimeOfDay inicial = const TimeOfDay(hour: 8, minute: 0);
    final partes = ctrl.text.split(':');
    if (partes.length == 2) {
      final h = int.tryParse(partes[0]);
      final m = int.tryParse(partes[1]);
      if (h != null && m != null) inicial = TimeOfDay(hour: h, minute: m);
    }

    final hora = await showTimePicker(context: context, initialTime: inicial);
    if (hora == null) return;

    ctrl.text =
    '${hora.hour.toString().padLeft(2, '0')}:'
        '${hora.minute.toString().padLeft(2, '0')}';
  }

  String? _validarRequerido(String? valor) =>
      (valor == null || valor.trim().isEmpty) ? 'Requerido' : null;

  String? _validarCapacidad(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Requerido';
    final numero = int.tryParse(valor.trim());
    if (numero == null) return 'Debe ser un número entero';
    if (numero <= 0) return 'Debe ser mayor a 0';
    return null;
  }

  // PANTALLA DE REGISTRO PARQUEADERO

  // Campo de localidad: se puede elegir de la lista o escribir
  Widget _campoLocalidad() {
    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<String>(
        textEditingController: _zonaCtrl,
        focusNode: _zonaFocus,
        optionsBuilder: (TextEditingValue value) {
          final consulta = _normalizar(value.text);
          if (consulta.isEmpty) return _localidades;
          return _localidades.where(
                (l) => _normalizar(l).contains(consulta),
          );
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              labelText: 'Localidad',
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            textCapitalization: TextCapitalization.words,
            validator: _validarLocalidad,
            onFieldSubmitted: (_) => onFieldSubmitted(),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 220,
                  maxWidth: constraints.maxWidth,
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    final opcion = options.elementAt(i);
                    return ListTile(
                      dense: true,
                      title: Text(opcion),
                      onTap: () => onSelected(opcion),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Campo de tarifa: acepta dígitos, puntos y comas.
  Widget _campoTarifa(TextEditingController ctrl, String etiqueta) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: etiqueta),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      validator: _validarTarifa,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registra tu Parqueadero'),
        centerTitle: true,
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
                decoration: const InputDecoration(
                  labelText: 'Nombre Parqueadero',
                ),
                textCapitalization: TextCapitalization.words,
                validator: _validarRequerido,
              ),
              _campoLocalidad(),
              TextFormField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(labelText: 'Dirección'),
                validator: _validarRequerido,
              ),
              TextFormField(
                controller: _representanteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Propietario o representante',
                ),
                textCapitalization: TextCapitalization.words,
                validator: _validarRequerido,
              ),
              TextFormField(
                controller: _capacidadCtrl,
                decoration: const InputDecoration(labelText: 'Capacidad total'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _validarCapacidad,
              ),
              _campoTarifa(_tarifaHoraCtrl, 'Tarifa por hora'),
              _campoTarifa(_tarifaDiaCtrl, 'Tarifa por día'),
              _campoTarifa(_tarifaNocheCtrl, 'Tarifa por noche'),
              TextFormField(
                controller: _horaInicioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Hora de inicio de atención',
                  suffixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: () => _seleccionarHora(_horaInicioCtrl),
                validator: _validarRequerido,
              ),
              TextFormField(
                controller: _horaFinalCtrl,
                decoration: const InputDecoration(
                  labelText: 'Hora final de atención',
                  suffixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: () => _seleccionarHora(_horaFinalCtrl),
                validator: _validarRequerido,
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
                onPressed: _registrar,
                child: const Text('Registrar parqueadero'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}