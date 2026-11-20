import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Medios de pago de la pasarela simulada y los datos que pide cada uno.
/// Los comparten el pago de una reserva y la recarga de la billetera.
enum EntradaPago { texto, numero, tarjeta, vencimiento, cvv }

class MedioPagoUi {
  const MedioPagoUi(this.codigo, this.nombre, this.icono, this.campos);
  final String codigo;
  final String nombre;
  final IconData icono;
  final List<CampoPago> campos;
}

class CampoPago {
  const CampoPago(
    this.clave,
    this.etiqueta,
    this.validador, {
    this.entrada = EntradaPago.texto,
  });
  final String clave;
  final String etiqueta;
  final String? Function(String valor) validador;
  final EntradaPago entrada;
}

String? _requerido(String v) => v.trim().isEmpty ? 'Requerido' : null;

String? _validarTarjeta(String v) {
  final digitos = v.replaceAll(' ', '');
  if (digitos.isEmpty) return 'Requerido';
  return digitos.length == 16 ? null : 'Debe tener 16 dígitos';
}

/// El vencimiento llega como MM/AA (lo escribe el calendario); la tarjeta vale hasta fin de ese mes.
String? _validarVencimiento(String v) {
  final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(v.trim());
  if (m == null) return 'Elige la fecha de vencimiento';
  final mes = int.parse(m.group(1)!);
  final anio = 2000 + int.parse(m.group(2)!);
  final hoy = DateTime.now();
  if (mes < 1 || mes > 12 || DateTime(anio, mes + 1).isBefore(DateTime(hoy.year, hoy.month + 1))) {
    return 'La tarjeta está vencida';
  }
  return null;
}

String? _validarCvv(String v) {
  if (v.isEmpty) return 'Requerido';
  return v.length >= 3 && v.length <= 4 ? null : 'Debe tener 3 o 4 dígitos';
}

String? _validarDocumento(String v) {
  if (v.isEmpty) return 'Requerido';
  return v.length >= 6 && v.length <= 10 ? null : 'Debe tener entre 6 y 10 dígitos';
}

String? _validarCelular(String v) {
  if (v.isEmpty) return 'Requerido';
  return RegExp(r'^3\d{9}$').hasMatch(v) ? null : 'Debe tener 10 dígitos y empezar por 3';
}

final mediosPago = <MedioPagoUi>[
  MedioPagoUi('TARJETA', 'Tarjeta', Icons.credit_card, [
    CampoPago('numeroTarjeta', 'Número de tarjeta', _validarTarjeta, entrada: EntradaPago.tarjeta),
    CampoPago('titular', 'Titular', _requerido),
    CampoPago('vencimiento', 'Vencimiento (MM/AA)', _validarVencimiento, entrada: EntradaPago.vencimiento),
    CampoPago('cvv', 'CVV', _validarCvv, entrada: EntradaPago.cvv),
  ]),
  MedioPagoUi('PSE', 'PSE', Icons.account_balance_outlined, [
    CampoPago('banco', 'Banco', _requerido),
    CampoPago('documento', 'Documento', _validarDocumento, entrada: EntradaPago.numero),
  ]),
  MedioPagoUi('NEQUI', 'Nequi', Icons.phone_android, [
    CampoPago('celular', 'Celular', _validarCelular, entrada: EntradaPago.numero),
  ]),
];

/// Agrupa los dígitos de la tarjeta de 4 en 4 (máximo 16).
class FormatoTarjeta extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue anterior, TextEditingValue nuevo) {
    final digitos = nuevo.text.replaceAll(RegExp(r'\D'), '');
    final corto = digitos.length > 16 ? digitos.substring(0, 16) : digitos;
    final texto = [
      for (var i = 0; i < corto.length; i += 4)
        corto.substring(i, i + 4 > corto.length ? corto.length : i + 4),
    ].join(' ');
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Pagar con el saldo de la billetera: no pide datos y solo sirve para reservas (no para recargar).
final medioSaldo = MedioPagoUi(
  'SALDO',
  'Mi saldo',
  Icons.account_balance_wallet_outlined,
  const [],
);
