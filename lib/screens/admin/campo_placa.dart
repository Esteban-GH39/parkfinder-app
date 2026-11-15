import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/estadia.dart';

/// Mayúsculas y sin espacios ni guiones: "abc-123" -> "ABC123" (igual que el backend).
String normalizarPlaca(String texto) =>
    texto.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

/// Entre 5 y 7 letras o números (ABC123 carro, ABC12D moto).
bool placaValida(String texto) =>
    RegExp(r'^[A-Z0-9]{5,7}$').hasMatch(normalizarPlaca(texto));

const mensajePlacaInvalida =
    'La placa debe tener entre 5 y 7 letras o números (ej. ABC123).';

/// Campo para digitar la placa: solo letras y números, en mayúsculas.
class CampoPlaca extends StatelessWidget {
  const CampoPlaca({
    super.key,
    required this.controller,
    this.etiqueta = 'Placa del vehículo',
    this.tipo = TipoVehiculo.carro,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String etiqueta;
  final TipoVehiculo tipo;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    textCapitalization: TextCapitalization.characters,
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
      LengthLimitingTextInputFormatter(7),
      _Mayusculas(),
    ],
    decoration: InputDecoration(
      labelText: etiqueta,
      hintText: tipo == TipoVehiculo.moto ? 'ABC12D' : 'ABC123',
      prefixIcon: Icon(
        tipo == TipoVehiculo.moto
            ? Icons.two_wheeler
            : Icons.directions_car_outlined,
      ),
    ),
    onSubmitted: onSubmitted,
  );
}

class _Mayusculas extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

/// Selector carro / moto.
class SelectorTipoVehiculo extends StatelessWidget {
  const SelectorTipoVehiculo({
    super.key,
    required this.valor,
    required this.onChanged,
  });

  final TipoVehiculo valor;
  final ValueChanged<TipoVehiculo>? onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<TipoVehiculo>(
    segments: const [
      ButtonSegment(
        value: TipoVehiculo.carro,
        label: Text('Carro'),
        icon: Icon(Icons.directions_car_outlined),
      ),
      ButtonSegment(
        value: TipoVehiculo.moto,
        label: Text('Moto'),
        icon: Icon(Icons.two_wheeler),
      ),
    ],
    selected: {valor},
    onSelectionChanged: onChanged == null
        ? null
        : (seleccion) => onChanged!(seleccion.first),
  );
}
