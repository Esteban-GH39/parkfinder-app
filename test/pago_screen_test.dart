import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/screens/cliente/pago_screen.dart';
import 'package:parkfinder_app/services/pago_service.dart';

/// Guarda lo que la pantalla le manda a la pasarela, sin red.
class _PagoServiceFalso extends PagoService {
  int llamadas = 0;
  String? medio;
  Map<String, String>? datos;

  @override
  Future<Map<String, dynamic>> pagar({
    required int reservaId,
    required String medio,
    required Map<String, String> datos,
  }) async {
    llamadas++;
    this.medio = medio;
    this.datos = datos;
    return {
      'success': true,
      'data': {
        'estado': 'APROBADO',
        'mensaje': 'Pago aprobado (simulado)',
        'monto': 3000,
        'detalle': 'Tarjeta **** 4242',
        'referencia': 'SIM-ABC123',
        'codigoReserva': 77,
      },
    };
  }
}

void main() {
  Future<_PagoServiceFalso> montar(
    WidgetTester tester, {
    Map<String, dynamic> reserva = const {'id': 5, 'cantidad': 1, 'cantidadMotos': 0},
  }) async {
    final servicio = _PagoServiceFalso();
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: PagoScreen(
          reserva: reserva,
          parqueadero: const {'nombre': 'Parqueadero Centro'},
          pagoService: servicio,
        ),
      ),
    );
    return servicio;
  }

  Future<void> escribir(WidgetTester tester, String campo, String texto) async {
    await tester.enterText(find.byKey(Key('campo_$campo')), texto);
    await tester.pump();
  }

  Future<void> pagar(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('botonPagar')));
    await tester.pump();
  }

  Future<void> llenarTarjeta(WidgetTester tester) async {
    await escribir(tester, 'numeroTarjeta', '4242424242424242');
    await escribir(tester, 'titular', 'Laura Gomez');
    await tester.tap(find.byKey(const Key('campo_vencimiento')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await escribir(tester, 'cvv', '123');
  }

  testWidgets('cada reserva cuesta lo mismo: 3.000 sin importar los cupos', (tester) async {
    await montar(tester, reserva: const {'id': 5, 'cantidad': 6, 'cantidadMotos': 2});

    expect((tester.widget(find.byKey(const Key('montoPago'))) as Text).data, '\$3.000');
    expect(find.text('Pagar \$3.000'), findsOneWidget);
  });

  testWidgets('usa el costo que informa el backend', (tester) async {
    await montar(tester, reserva: const {'id': 5, 'cantidad': 1, 'costoReserva': 4500});

    expect((tester.widget(find.byKey(const Key('montoPago'))) as Text).data, '\$4.500');
  });

  testWidgets('la tarjeta se agrupa de 4 en 4 y no pasa de 16 dígitos', (tester) async {
    await montar(tester);

    await escribir(tester, 'numeroTarjeta', '42424242424242429999');

    expect(find.text('4242 4242 4242 4242'), findsOneWidget);
  });

  testWidgets('sin datos o con la tarjeta incompleta no paga y avisa', (tester) async {
    final servicio = await montar(tester);

    await pagar(tester);
    expect(find.text('Requerido'), findsWidgets);

    await escribir(tester, 'numeroTarjeta', '4242 4242 4242 424');
    await pagar(tester);
    expect(find.text('Debe tener 16 dígitos'), findsOneWidget);
    expect(servicio.llamadas, 0);
  });

  testWidgets('el vencimiento se elige en un calendario y queda como MM/AA', (tester) async {
    await montar(tester);

    await tester.tap(find.byKey(const Key('campo_vencimiento')));
    await tester.pumpAndSettle();
    expect(find.text('Vencimiento de la tarjeta'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final hoy = DateTime.now();
    final esperado =
        '${hoy.month.toString().padLeft(2, '0')}/${((hoy.year + 2) % 100).toString().padLeft(2, '0')}';
    expect(find.text(esperado), findsOneWidget);
  });

  testWidgets('el CVV pide 3 o 4 dígitos', (tester) async {
    final servicio = await montar(tester);

    await escribir(tester, 'cvv', '12');
    await pagar(tester);

    expect(find.text('Debe tener 3 o 4 dígitos'), findsOneWidget);
    expect(servicio.llamadas, 0);
  });

  testWidgets('con los datos bien paga y muestra el código de reserva', (tester) async {
    final servicio = await montar(tester);

    await llenarTarjeta(tester);
    await pagar(tester);
    await tester.pump();

    expect(servicio.llamadas, 1);
    expect(servicio.medio, 'TARJETA');
    expect(servicio.datos!['numeroTarjeta'], '4242 4242 4242 4242');
    expect(find.text('Pago aprobado'), findsOneWidget);
    expect((tester.widget(find.byKey(const Key('codigoReserva'))) as Text).data, '77');
  });

  testWidgets('Nequi pide un celular de 10 dígitos que empiece por 3', (tester) async {
    final servicio = await montar(tester);

    await tester.tap(find.byKey(const Key('medioNEQUI')));
    await tester.pump();
    await escribir(tester, 'celular', '2001234567');
    await pagar(tester);
    expect(find.text('Debe tener 10 dígitos y empezar por 3'), findsOneWidget);
    expect(servicio.llamadas, 0);

    await escribir(tester, 'celular', '3001234567');
    await pagar(tester);
    await tester.pump();
    expect(servicio.llamadas, 1);
    expect(servicio.medio, 'NEQUI');
  });
}
