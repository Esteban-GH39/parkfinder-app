import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/models/comprobante.dart';
import 'package:parkfinder_app/screens/admin/codigo_reserva_screen.dart';

import 'hu21_servicios_falsos.dart';

/// HU-21: validación del comprobante de pago y descuento del cupo reservado.
void main() {
  late ParqueaderoServiceFalso parqueaderos;
  late ComprobanteServiceFalso comprobantes;
  int? cuposDevueltos;

  setUp(() {
    parqueaderos = ParqueaderoServiceFalso();
    comprobantes = ComprobanteServiceFalso(comprobante: comprobanteDePrueba());
    cuposDevueltos = null;
  });

  /// Abre la pantalla desde otra ruta para poder leer el valor con que cierra.
  Future<void> montar(WidgetTester tester, {int cuposDisponibles = 30}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              cuposDevueltos = await Navigator.push<int>(
                context,
                MaterialPageRoute(
                  builder: (_) => CodigoReservaScreen(
                    parqueadero: parqueaderoDePrueba(),
                    cuposDisponibles: cuposDisponibles,
                    parqueaderoService: parqueaderos,
                    comprobanteService: comprobantes,
                  ),
                ),
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> validarComprobante(WidgetTester tester, String id) async {
    await tester.enterText(find.byType(TextField), id);
    await tester.tap(find.text('Validar comprobante'));
    await tester.pump();
  }

  ElevatedButton botonValidarReserva(WidgetTester tester) =>
      tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Validar reserva'),
      );

  testWidgets('muestra el campo del comprobante y la reserva deshabilitada',
      (tester) async {
    await montar(tester);

    expect(find.text('Código de reserva'), findsOneWidget);
    expect(find.text('Id del comprobante de pago'), findsOneWidget);
    expect(find.text('Validar comprobante'), findsOneWidget);
    expect(botonValidarReserva(tester).onPressed, isNull);
  });

  testWidgets('sin id no consulta el comprobante', (tester) async {
    await montar(tester);

    await tester.tap(find.text('Validar comprobante'));
    await tester.pump();

    expect(comprobantes.vecesConsultado, 0);
    expect(find.text('Ingrese un id de comprobante válido.'), findsOneWidget);
  });

  testWidgets('un comprobante aprobado muestra sus datos y habilita la reserva',
      (tester) async {
    await montar(tester);

    await validarComprobante(tester, '15');

    expect(comprobantes.idConsultado, 15);
    expect(find.text('Id comprobante'), findsOneWidget);
    expect(find.text('2026-10-28'), findsOneWidget);
    expect(find.text('\$12000'), findsOneWidget);
    expect(find.text('NEQUI'), findsOneWidget);
    expect(find.text('APROBADO'), findsOneWidget);
    expect(botonValidarReserva(tester).onPressed, isNotNull);
  });

  testWidgets('el estado se compara sin importar mayúsculas ni espacios',
      (tester) async {
    comprobantes.comprobante = comprobanteDePrueba(estado: '  aprobado ');
    await montar(tester);

    await validarComprobante(tester, '15');

    expect(botonValidarReserva(tester).onPressed, isNotNull);
  });

  group('rechaza el comprobante', () {
    Future<void> esperarError(
      WidgetTester tester,
      Comprobante comprobante,
      String mensaje,
    ) async {
      comprobantes.comprobante = comprobante;
      await montar(tester);

      await validarComprobante(tester, '15');

      expect(find.text(mensaje), findsOneWidget);
      expect(find.text('Id comprobante'), findsNothing);
      expect(botonValidarReserva(tester).onPressed, isNull);
    }

    testWidgets('si es de otro parqueadero', (tester) async {
      await esperarError(
        tester,
        comprobanteDePrueba(parqueaderoId: 99),
        'El comprobante 15 no pertenece a este parqueadero.',
      );
    });

    testWidgets('si el pago está pendiente', (tester) async {
      await esperarError(
        tester,
        comprobanteDePrueba(estado: 'PENDIENTE'),
        'El pago del comprobante 15 aún está pendiente.',
      );
    });

    testWidgets('si el pago fue rechazado', (tester) async {
      await esperarError(
        tester,
        comprobanteDePrueba(estado: 'rechazado'),
        'El pago del comprobante 15 fue rechazado.',
      );
    });

    testWidgets('si tiene otro estado', (tester) async {
      await esperarError(
        tester,
        comprobanteDePrueba(estado: 'ANULADO'),
        'El comprobante 15 no está aprobado (estado: ANULADO).',
      );
    });

    testWidgets('si no tiene estado', (tester) async {
      await esperarError(
        tester,
        comprobanteDePrueba(estado: null),
        'El comprobante 15 no está aprobado (estado: sin estado).',
      );
    });
  });

  testWidgets('si la consulta falla muestra el error sin "Exception:"',
      (tester) async {
    comprobantes.error = Exception('No existe un comprobante con id 15.');
    await montar(tester);

    await validarComprobante(tester, '15');

    expect(find.text('No existe un comprobante con id 15.'), findsOneWidget);
  });

  testWidgets('mientras consulta muestra el indicador', (tester) async {
    final respuesta = Completer<Comprobante>();
    comprobantes.respuesta = respuesta;
    await montar(tester);

    await validarComprobante(tester, '15');

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Validar comprobante'), findsNothing);

    respuesta.complete(comprobanteDePrueba());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('APROBADO'), findsOneWidget);
  });

  testWidgets('validar la reserva descuenta un cupo y cierra con el nuevo valor',
      (tester) async {
    await montar(tester);

    await validarComprobante(tester, '15');
    await tester.ensureVisible(find.text('Validar reserva'));
    await tester.tap(find.text('Validar reserva'));
    await tester.pumpAndSettle();

    expect(parqueaderos.idParqueaderoEnviado, 7);
    expect(parqueaderos.idAdminEnviado, 3);
    expect(parqueaderos.cuposEnviados, 29);
    expect(find.byType(CodigoReservaScreen), findsNothing);
    expect(cuposDevueltos, 29);
  });

  testWidgets('sin cupos disponibles no valida la reserva', (tester) async {
    await montar(tester, cuposDisponibles: 0);

    await validarComprobante(tester, '15');
    await tester.ensureVisible(find.text('Validar reserva'));
    await tester.tap(find.text('Validar reserva'));
    await tester.pump();

    expect(parqueaderos.vecesActualizado, 0);
    expect(
      find.text('No hay cupos disponibles para descontar.'),
      findsOneWidget,
    );
    expect(find.byType(CodigoReservaScreen), findsOneWidget);
  });

  testWidgets('si el backend rechaza la reserva se queda en la pantalla',
      (tester) async {
    parqueaderos.errorActualizar = Exception('Error al actualizar cupos (500)');
    await montar(tester);

    await validarComprobante(tester, '15');
    await tester.ensureVisible(find.text('Validar reserva'));
    await tester.tap(find.text('Validar reserva'));
    await tester.pump();

    expect(find.text('Error al actualizar cupos (500)'), findsOneWidget);
    expect(find.byType(CodigoReservaScreen), findsOneWidget);
    expect(cuposDevueltos, isNull);
  });
}
