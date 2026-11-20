import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/billetera_service.dart';
import '../../services/sesion_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets_comunes.dart';
import '../../utils/formato.dart';
import 'medios_pago.dart';

/// Billetera del cliente: saldo, recarga con la pasarela simulada (tarjeta, PSE o Nequi) y movimientos.
/// El saldo sirve para pagar reservas, y las reservas canceladas lo recuperan.
class BilleteraScreen extends StatefulWidget {
  const BilleteraScreen({super.key, BilleteraService? servicio})
    : _servicio = servicio;

  final BilleteraService? _servicio;

  @override
  State<BilleteraScreen> createState() => _BilleteraScreenState();
}

const _montosRapidos = [10000, 20000, 50000, 100000];

class _BilleteraScreenState extends State<BilleteraScreen> {
  final _formKey = GlobalKey<FormState>();
  late final BilleteraService _servicio =
      widget._servicio ?? BilleteraService();

  final _montoCtrl = TextEditingController();
  final Map<String, TextEditingController> _controles = {};
  MedioPagoUi _medio = mediosPago.first;

  int? _saldo;
  List<Map<String, dynamic>> _movimientos = [];
  bool _cargando = true;
  bool _recargando = false;
  String? _error;
  String? _exito;

  TextEditingController _control(String clave) =>
      _controles.putIfAbsent(clave, TextEditingController.new);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    for (final c in _controles.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargar() async {
    final id = SesionService.instancia.id;
    if (id == null) {
      setState(() => _cargando = false);
      return;
    }
    setState(() => _cargando = true);
    final resultados = await Future.wait([
      _servicio.saldo(id),
      _servicio.movimientos(id),
    ]);
    if (!mounted) return;
    setState(() {
      _saldo = resultados[0] as int?;
      _movimientos = resultados[1] as List<Map<String, dynamic>>;
      _cargando = false;
    });
  }

  int get _monto => int.tryParse(_montoCtrl.text.replaceAll('.', '')) ?? 0;

  String? _validarMonto(String? v) {
    final n = int.tryParse((v ?? '').replaceAll('.', '').trim());
    if (n == null) return 'Escribe el valor a recargar';
    if (n < 5000) return 'La recarga mínima es de \$5.000';
    if (n > 500000) return 'La recarga máxima es de \$500.000';
    return null;
  }

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

  Future<void> _recargar() async {
    final id = SesionService.instancia.id;
    if (id == null || !_formKey.currentState!.validate()) return;
    setState(() {
      _recargando = true;
      _error = null;
      _exito = null;
    });
    final r = await _servicio.recargar(
      clienteId: id,
      monto: _monto,
      medio: _medio.codigo,
      datos: {
        for (final campo in _medio.campos)
          campo.clave: _control(campo.clave).text.trim(),
      },
    );
    if (!mounted) return;
    if (r['success'] != true) {
      setState(() {
        _recargando = false;
        _error = '${r['error']}';
      });
      return;
    }
    final data = r['data'] as Map<String, dynamic>;
    final aprobada = data['estado'] == 'APROBADO';
    setState(() {
      _recargando = false;
      if (aprobada) {
        _exito = 'Recarga aprobada. Tu saldo es ${pesos(data['saldo'] as num)}.';
        _montoCtrl.clear();
        for (final c in _controles.values) {
          c.clear();
        }
      } else {
        _error = '${data['mensaje'] ?? 'La recarga fue rechazada'}';
      }
    });
    if (aprobada) _cargar();
  }

  TextInputType _teclado(EntradaPago e) =>
      e == EntradaPago.texto ? TextInputType.text : TextInputType.number;

  List<TextInputFormatter> _formatos(EntradaPago e) => switch (e) {
    EntradaPago.tarjeta => [FormatoTarjeta()],
    EntradaPago.cvv => [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(4),
    ],
    EntradaPago.numero => [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(10),
    ],
    _ => const [],
  };

  Widget _campo(CampoPago campo) {
    final esVencimiento = campo.entrada == EntradaPago.vencimiento;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: Key('campo_${campo.clave}'),
        controller: _control(campo.clave),
        keyboardType: _teclado(campo.entrada),
        inputFormatters: _formatos(campo.entrada),
        obscureText: campo.entrada == EntradaPago.cvv,
        readOnly: esVencimiento,
        onTap: esVencimiento ? _elegirVencimiento : null,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) => campo.validador((v ?? '').trim()),
        decoration: InputDecoration(
          labelText: campo.etiqueta,
          suffixIcon: esVencimiento
              ? const Icon(Icons.calendar_month_outlined)
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi billetera')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _TarjetaSaldo(saldo: _saldo, cargando: _cargando),
              const SizedBox(height: 16),
              _formularioRecarga(),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'Movimientos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              if (_movimientos.isEmpty && !_cargando)
                const TarjetaBlanca(
                  child: Text(
                    'Aún no tienes movimientos',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textoSuave),
                  ),
                )
              else
                for (final m in _movimientos) ...[
                  _FilaMovimiento(movimiento: m),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _formularioRecarga() {
    return TarjetaBlanca(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recargar saldo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in _montosRapidos)
                  ActionChip(
                    key: Key('montoRapido_$m'),
                    label: Text(pesos(m)),
                    onPressed: () => setState(() => _montoCtrl.text = '$m'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('campoMonto'),
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(7),
              ],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: _validarMonto,
              decoration: const InputDecoration(
                labelText: 'Valor a recargar',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Medio de pago',
              style: TextStyle(
                color: AppColors.textoSuave,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final medio in mediosPago) ...[
                  Expanded(
                    child: _PastillaMedio(
                      key: Key('medioRecarga${medio.codigo}'),
                      medio: medio,
                      activa: medio == _medio,
                      onTap: () => setState(() {
                        _medio = medio;
                        _error = null;
                      }),
                    ),
                  ),
                  if (medio != mediosPago.last) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 16),
            for (final campo in _medio.campos) _campo(campo),
            const Text(
              'Pasarela simulada: no se hace ningún cobro real.',
              style: TextStyle(color: AppColors.textoSuave, fontSize: 12),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              AvisoError(texto: _error!),
            ],
            if (_exito != null) ...[
              const SizedBox(height: 12),
              Container(
                key: const Key('avisoRecargaExitosa'),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.exitoSuave,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  _exito!,
                  style: const TextStyle(
                    color: AppColors.exito,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('botonRecargar'),
              onPressed: _recargando ? null : _recargar,
              child: _recargando
                  ? const CargandoEnBoton()
                  : const Text('Recargar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaSaldo extends StatelessWidget {
  const _TarjetaSaldo({required this.saldo, required this.cargando});
  final int? saldo;
  final bool cargando;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.oscuro,
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white70,
              size: 18,
            ),
            SizedBox(width: 8),
            Text('Saldo disponible', style: TextStyle(color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          saldo == null ? (cargando ? '...' : '—') : pesos(saldo!),
          key: const Key('saldoBilletera'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _PastillaMedio extends StatelessWidget {
  const _PastillaMedio({
    super.key,
    required this.medio,
    required this.activa,
    required this.onTap,
  });
  final MedioPagoUi medio;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
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
            Flexible(
              child: Text(
                medio.nombre,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: activa ? Colors.white : AppColors.textoSuave,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FilaMovimiento extends StatelessWidget {
  const _FilaMovimiento({required this.movimiento});
  final Map<String, dynamic> movimiento;

  @override
  Widget build(BuildContext context) {
    final monto = (movimiento['monto'] as num?) ?? 0;
    final entra = monto >= 0;
    final tipo = movimiento['tipo'];
    final icono = switch (tipo) {
      'RECARGA' => Icons.add_card_outlined,
      'REEMBOLSO' => Icons.undo,
      _ => Icons.local_parking,
    };
    return Container(
      key: Key('movimiento_${movimiento['id']}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: entra ? AppColors.exitoSuave : AppColors.chip,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icono,
              size: 20,
              color: entra ? AppColors.exito : AppColors.textoSuave,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${movimiento['detalle'] ?? tipo}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fechaHora(movimiento['creadoEn']),
                  style: const TextStyle(
                    color: AppColors.textoSuave,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entra ? '+' : '-'}${pesos(monto.abs())}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: entra ? AppColors.exito : AppColors.texto,
            ),
          ),
        ],
      ),
    );
  }
}
