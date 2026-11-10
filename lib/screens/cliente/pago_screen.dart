import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/pago_service.dart';
import '../../theme/app_theme.dart';

/// HU-07: elegir un medio de pago, llenar sus datos y pagar con la pasarela simulada.
/// Se valida el formato de los datos (tarjeta de 16 dígitos, vencimiento, CVV...); con buen formato
/// se aprueba, salvo una tarjeta que termine en 0000, que se rechaza para poder probar ese caso.
/// Cada reserva cuesta lo mismo ([_costoPorDefecto] si el backend no lo informa).
class PagoScreen extends StatefulWidget {
  const PagoScreen({
    super.key,
    required this.reserva,
    required this.parqueadero,
    PagoService? pagoService,
  }) : _pagoService = pagoService;

  /// Reserva tal como la devuelve `POST /reservas`.
  final Map<String, dynamic> reserva;
  final Map<String, dynamic> parqueadero;
  final PagoService? _pagoService;

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

const _costoPorDefecto = 3000;

enum _Entrada { texto, numero, tarjeta, vencimiento, cvv }

class _Medio {
  const _Medio(this.codigo, this.nombre, this.icono, this.campos);
  final String codigo;
  final String nombre;
  final IconData icono;
  final List<_Campo> campos;
}

class _Campo {
  const _Campo(
    this.clave,
    this.etiqueta,
    this.validador, {
    this.entrada = _Entrada.texto,
  });
  final String clave;
  final String etiqueta;
  final String? Function(String valor) validador;
  final _Entrada entrada;
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

final _medios = <_Medio>[
  _Medio('TARJETA', 'Tarjeta', Icons.credit_card, [
    _Campo('numeroTarjeta', 'Número de tarjeta', _validarTarjeta, entrada: _Entrada.tarjeta),
    _Campo('titular', 'Titular', _requerido),
    _Campo('vencimiento', 'Vencimiento (MM/AA)', _validarVencimiento, entrada: _Entrada.vencimiento),
    _Campo('cvv', 'CVV', _validarCvv, entrada: _Entrada.cvv),
  ]),
  _Medio('PSE', 'PSE', Icons.account_balance_outlined, [
    _Campo('banco', 'Banco', _requerido),
    _Campo('documento', 'Documento', _validarDocumento, entrada: _Entrada.numero),
  ]),
  _Medio('NEQUI', 'Nequi', Icons.phone_android, [
    _Campo('celular', 'Celular', _validarCelular, entrada: _Entrada.numero),
  ]),
];

/// Agrupa los dígitos de la tarjeta de 4 en 4 (máximo 16).
class _FormatoTarjeta extends TextInputFormatter {
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

class _PagoScreenState extends State<PagoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final PagoService _servicio = widget._pagoService ?? PagoService();

  _Medio _medio = _medios.first;
  final Map<String, TextEditingController> _controles = {};
  bool _cargando = false;
  String? _error;
  Map<String, dynamic>? _pago;

  TextEditingController _control(String clave) =>
      _controles.putIfAbsent(clave, TextEditingController.new);

  @override
  void dispose() {
    for (final c in _controles.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _motos => (widget.reserva['cantidadMotos'] as num?)?.toInt() ?? 0;
  int get _cupos => (widget.reserva['cantidad'] as num?)?.toInt() ?? 1;
  int get _carros => _cupos - _motos;

  /// Lo que cuesta cada reserva: el mismo valor sin importar cuántos cupos ni de qué tipo.
  num get _monto => (widget.reserva['costoReserva'] as num?) ?? _costoPorDefecto;

  String get _textoCupos => [
    if (_carros > 0) '$_carros ${_carros == 1 ? 'carro' : 'carros'}',
    if (_motos > 0) '$_motos ${_motos == 1 ? 'moto' : 'motos'}',
  ].join(' · ');

  Future<void> _elegirVencimiento() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      helpText: 'Vencimiento de la tarjeta',
      initialDate: DateTime(hoy.year + 2, hoy.month),
      firstDate: DateTime(hoy.year, hoy.month),
      lastDate: DateTime(hoy.year + 15, 12),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (fecha == null) return;
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = (fecha.year % 100).toString().padLeft(2, '0');
    setState(() => _control('vencimiento').text = '$mes/$anio');
    _formKey.currentState?.validate();
  }

  Future<void> _pagar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    final resultado = await _servicio.pagar(
      reservaId: (widget.reserva['id'] as num).toInt(),
      medio: _medio.codigo,
      datos: {
        for (final campo in _medio.campos)
          campo.clave: _control(campo.clave).text.trim(),
      },
    );
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (resultado['success'] == true) {
        _pago = resultado['data'] as Map<String, dynamic>;
      } else {
        _error = '${resultado['error']}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagar reserva')),
      body: SafeArea(child: _pago == null ? _formulario() : _resultado()),
    );
  }

  TextInputType _teclado(_Entrada e) => switch (e) {
    _Entrada.texto => TextInputType.text,
    _ => TextInputType.number,
  };

  List<TextInputFormatter> _formatos(_Entrada e) => switch (e) {
    _Entrada.tarjeta => [_FormatoTarjeta()],
    _Entrada.cvv => [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(4),
    ],
    _Entrada.numero => [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(10),
    ],
    _ => const [],
  };

  Widget _campo(_Campo campo) {
    final esVencimiento = campo.entrada == _Entrada.vencimiento;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: Key('campo_${campo.clave}'),
        controller: _control(campo.clave),
        keyboardType: _teclado(campo.entrada),
        inputFormatters: _formatos(campo.entrada),
        obscureText: campo.entrada == _Entrada.cvv,
        readOnly: esVencimiento,
        onTap: esVencimiento ? _elegirVencimiento : null,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) => campo.validador((v ?? '').trim()),
        decoration: InputDecoration(
          labelText: campo.etiqueta,
          suffixIcon: esVencimiento ? const Icon(Icons.calendar_month_outlined) : null,
        ),
      ),
    );
  }

  Widget _formulario() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              children: [
                _Tarjeta(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.parqueadero['nombre'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Costo de la reserva${_textoCupos.isEmpty ? '' : ' · $_textoCupos'}',
                              style: const TextStyle(
                                color: AppColors.textoSuave,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        key: const Key('montoPago'),
                        '\$${_miles(_monto)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Tarjeta(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medio de pago',
                        style: TextStyle(
                          color: AppColors.textoSuave,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (final medio in _medios) ...[
                            _Pastilla(
                              key: Key('medio${medio.codigo}'),
                              medio: medio,
                              activa: medio == _medio,
                              onTap: () => setState(() {
                                _medio = medio;
                                _error = null;
                              }),
                            ),
                            if (medio != _medios.last) const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 18),
                      for (final campo in _medio.campos) _campo(campo),
                      const Text(
                        'Pasarela simulada: no se hace ningún cobro real.',
                        style: TextStyle(
                          color: AppColors.textoSuave,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _Aviso(texto: _error!),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: FilledButton(
              key: const Key('botonPagar'),
              onPressed: _cargando ? null : _pagar,
              child: _cargando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Pagar \$${_miles(_monto)}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultado() {
    final pago = _pago!;
    final aprobado = pago['estado'] == 'APROBADO';
    final codigo = pago['codigoReserva'];
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              _Tarjeta(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Icon(
                      aprobado ? Icons.check_circle : Icons.cancel,
                      size: 72,
                      color: aprobado ? AppColors.acento : AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      key: const Key('estadoPago'),
                      aprobado ? 'Pago aprobado' : 'Pago rechazado',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pago['mensaje'] ?? ''}',
                      style: const TextStyle(
                        color: AppColors.textoSuave,
                        fontSize: 13,
                      ),
                    ),
                    if (aprobado && codigo != null) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Código de reserva',
                        style: TextStyle(
                          color: AppColors.textoSuave,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$codigo',
                        key: const Key('codigoReserva'),
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Muéstralo al dueño del parqueadero cuando llegues',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textoSuave,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Tarjeta(
                child: Column(
                  children: [
                    _Fila('Valor', '\$${_miles(pago['monto'] as num)}'),
                    const Divider(height: 24, color: AppColors.borde),
                    _Fila('Medio', '${pago['detalle']}'),
                    const Divider(height: 24, color: AppColors.borde),
                    _Fila('Referencia', '${pago['referencia']}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: FilledButton(
            key: const Key('botonResultado'),
            onPressed: () => aprobado
                ? Navigator.of(context).pop(pago)
                : setState(() => _pago = null),
            child: Text(aprobado ? 'Listo' : 'Intentar de nuevo'),
          ),
        ),
      ],
    );
  }

  String _miles(num valor) {
    final n = valor.round().toString();
    return n.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.superficie,
      borderRadius: BorderRadius.circular(28),
    ),
    child: child,
  );
}

class _Pastilla extends StatelessWidget {
  const _Pastilla({
    super.key,
    required this.medio,
    required this.activa,
    required this.onTap,
  });
  final _Medio medio;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: activa ? AppColors.oscuro : AppColors.chip,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                medio.icono,
                size: 16,
                color: activa ? Colors.white : AppColors.textoSuave,
              ),
              const SizedBox(width: 6),
              Text(
                medio.nombre,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: activa ? Colors.white : AppColors.textoSuave,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Fila extends StatelessWidget {
  const _Fila(this.etiqueta, this.valor);
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(etiqueta, style: const TextStyle(color: AppColors.textoSuave)),
      const SizedBox(width: 16),
      Flexible(
        child: Text(
          valor,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.errorSuave,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}
