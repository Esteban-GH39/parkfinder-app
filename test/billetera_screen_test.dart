import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/screens/cliente/billetera_screen.dart';
import 'package:parkfinder_app/services/billetera_service.dart';
import 'package:parkfinder_app/services/sesion_service.dart';

class _BilleteraFalsa extends BilleteraService {
  int saldoActual = 8000;
  Map<String, dynamic> respuesta = {
    'success': true,
    'data': {'estado': 'APROBADO', 'saldo': 28000, 'mensaje': 'Pago aprobado (simulado)'},
  };
  final recargas = <Map<String, dynamic>>[];

  @override
  Future<int?> saldo(int clienteId) async => saldoActual;

  @override
  Future<List<Map<String, dynamic>>> movimientos(int clienteId) async => [
    {
      'id': 1,
      'tipo': 'REEMBOLSO',
      'monto': 3000,
      'detalle': 'Reembolso de la reserva #4',
      'creadoEn': '2026-11-18T10:00:00',
    },
    {
      'id': 2,
      'tipo': 'PAGO_RESERVA',
      'monto': -3000,
      'detalle': 'Pago de la reserva #4',
      'creadoEn': '2026-11-18T09:00:00',
    },
  ];

  @override
  Future<Map<String, dynamic>> recargar({
    required int clienteId,
    required int monto,
    required String medio,
    required Map<String, String> datos,
  }) async {
    recargas.add({'clienteId': clienteId, 'monto': monto, 'medio': medio, 'datos': datos});
    return respuesta;
  }
}

void main() {
  Future<_BilleteraFalsa> montar(WidgetTester tester) async {
    SesionService.instancia.iniciar(id: 5, nombre: 'Ana', correo: 'ana@test.com', rol: 'CLIENTE');
    final servicio = _BilleteraFalsa();
    await tester.pumpWidget(MaterialApp(home: BilleteraScreen(servicio: servicio)));
    await tester.pumpAndSettle();
    return servicio;
  }

  testWidgets('muestra el saldo y los movimientos', (tester) async {
    await montar(tester);
    expect(find.text('\$8.000'), findsOneWidget);
    expect(find.byKey(const Key('movimiento_1')), findsOneWidget);
    expect(find.text('+\$3.000'), findsOneWidget);
    expect(find.text('-\$3.000'), findsOneWidget);
  });

  testWidgets('un monto por debajo del mínimo no se envía', (tester) async {
    final servicio = await montar(tester);
    await tester.enterText(find.byKey(const Key('campoMonto')), '1000');
    await tester.tap(find.byKey(const Key('medioRecargaNEQUI')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo_celular')), '3001234567');
    await tester.ensureVisible(find.byKey(const Key('botonRecargar')));
    await tester.tap(find.byKey(const Key('botonRecargar')));
    await tester.pumpAndSettle();

    expect(find.text('La recarga mínima es de \$5.000'), findsOneWidget);
    expect(servicio.recargas, isEmpty);
  });

  testWidgets('recarga con Nequi: envía monto y celular y muestra el nuevo saldo', (tester) async {
    final servicio = await montar(tester);
    await tester.tap(find.byKey(const Key('montoRapido_20000')));
    await tester.tap(find.byKey(const Key('medioRecargaNEQUI')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo_celular')), '3001234567');
    await tester.ensureVisible(find.byKey(const Key('botonRecargar')));
    await tester.tap(find.byKey(const Key('botonRecargar')));
    await tester.pumpAndSettle();

    expect(servicio.recargas.single['monto'], 20000);
    expect(servicio.recargas.single['medio'], 'NEQUI');
    expect(servicio.recargas.single['datos'], {'celular': '3001234567'});
    expect(find.byKey(const Key('avisoRecargaExitosa')), findsOneWidget);
    expect(find.textContaining('\$28.000'), findsOneWidget);
  });

  testWidgets('una recarga rechazada por la pasarela muestra el motivo', (tester) async {
    final servicio = await montar(tester);
    servicio.respuesta = {
      'success': true,
      'data': {'estado': 'RECHAZADO', 'saldo': 8000, 'mensaje': 'Fondos insuficientes (simulado)'},
    };
    await tester.tap(find.byKey(const Key('montoRapido_10000')));
    await tester.tap(find.byKey(const Key('medioRecargaNEQUI')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo_celular')), '3001234567');
    await tester.ensureVisible(find.byKey(const Key('botonRecargar')));
    await tester.tap(find.byKey(const Key('botonRecargar')));
    await tester.pumpAndSettle();

    expect(find.text('Fondos insuficientes (simulado)'), findsOneWidget);
    expect(find.byKey(const Key('avisoRecargaExitosa')), findsNothing);
  });
}
