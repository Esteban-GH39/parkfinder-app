import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/models/parqueadero.dart';
import 'package:parkfinder_app/screens/admin/codigo_reserva_screen.dart';
import 'package:parkfinder_app/screens/admin/gestion_cupos_parqueadero_screen.dart';

import 'hu21_servicios_falsos.dart';

/// HU-21: el administrador descuenta o libera cupos de un parqueadero.
void main() {
  Future<void> montar(
    WidgetTester tester,
    ParqueaderoServiceFalso api, {
    Parqueadero? parqueadero,
    ComprobanteServiceFalso? comprobantes,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GestionCuposParqueaderoScreen(
          parqueadero: parqueadero ?? parqueaderoDePrueba(),
          parqueaderoService: api,
          comprobanteService: comprobantes,
        ),
      ),
    );
  }

  testWidgets('muestra el parqueadero, la capacidad y los cupos',
      (tester) async {
    await montar(tester, ParqueaderoServiceFalso());

    expect(find.text('Gestión de cupos'), findsOneWidget);
    expect(find.text('Parqueadero Centro'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('Código de reserva'), findsOneWidget);
    expect(find.text('Ingreso directo (-1 cupo)'), findsOneWidget);
    expect(find.text('Liberar cupo (+1 cupo)'), findsOneWidget);
  });

  testWidgets('ingreso directo descuenta un cupo', (tester) async {
    final api = ParqueaderoServiceFalso();
    await montar(tester, api);

    await tester.tap(find.text('Ingreso directo (-1 cupo)'));
    await tester.pump();

    expect(api.vecesActualizado, 1);
    expect(api.idParqueaderoEnviado, 7);
    expect(api.idAdminEnviado, 3);
    expect(api.cuposEnviados, 29);
    expect(find.text('29'), findsOneWidget);
    expect(find.text('Cupos actualizados correctamente.'), findsOneWidget);
  });

  testWidgets('liberar cupo agrega un cupo', (tester) async {
    final api = ParqueaderoServiceFalso();
    await montar(tester, api);

    await tester.tap(find.text('Liberar cupo (+1 cupo)'));
    await tester.pump();

    expect(api.cuposEnviados, 31);
    expect(find.text('31'), findsOneWidget);
  });

  testWidgets('sin cupos no permite el ingreso directo', (tester) async {
    final api = ParqueaderoServiceFalso();
    await montar(
      tester,
      api,
      parqueadero: parqueaderoDePrueba(cuposDisponibles: 0),
    );

    await tester.tap(find.text('Ingreso directo (-1 cupo)'));
    await tester.pump();

    expect(api.vecesActualizado, 0);
    expect(
      find.text('No hay cupos disponibles para descontar.'),
      findsOneWidget,
    );
  });

  testWidgets('no permite liberar cupos por encima de la capacidad',
      (tester) async {
    final api = ParqueaderoServiceFalso();
    await montar(
      tester,
      api,
      parqueadero: parqueaderoDePrueba(cuposDisponibles: 50),
    );

    await tester.tap(find.text('Liberar cupo (+1 cupo)'));
    await tester.pump();

    expect(api.vecesActualizado, 0);
    expect(
      find.text(
        'La cantidad de cupos no puede superar la capacidad total (50).',
      ),
      findsOneWidget,
    );
  });

  testWidgets('si el backend rechaza, muestra el error y no cambia los cupos',
      (tester) async {
    final api = ParqueaderoServiceFalso(
      errorActualizar: Exception('Parqueadero no encontrado'),
    );
    await montar(tester, api);

    await tester.tap(find.text('Ingreso directo (-1 cupo)'));
    await tester.pump();

    expect(find.text('Parqueadero no encontrado'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('mientras actualiza muestra el indicador y bloquea los botones',
      (tester) async {
    final respuesta = Completer<bool>();
    final api = ParqueaderoServiceFalso(respuestaActualizar: respuesta);
    await montar(tester, api);

    await tester.tap(find.text('Ingreso directo (-1 cupo)'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    for (final boton in tester.widgetList<ElevatedButton>(
      find.byType(ElevatedButton),
    )) {
      expect(boton.onPressed, isNull);
    }

    respuesta.complete(true);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('29'), findsOneWidget);
  });

  testWidgets('código de reserva abre la validación con los cupos actuales',
      (tester) async {
    await montar(tester, ParqueaderoServiceFalso());

    await tester.tap(find.text('Código de reserva'));
    await tester.pumpAndSettle();

    final codigo = tester.widget<CodigoReservaScreen>(
      find.byType(CodigoReservaScreen),
    );
    expect(codigo.parqueadero.id, 7);
    expect(codigo.cuposDisponibles, 30);
  });

  testWidgets('al validar una reserva vuelve con los cupos actualizados',
      (tester) async {
    final api = ParqueaderoServiceFalso();
    await montar(
      tester,
      api,
      comprobantes: ComprobanteServiceFalso(comprobante: comprobanteDePrueba()),
    );

    await tester.tap(find.text('Código de reserva'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '15');
    await tester.tap(find.text('Validar comprobante'));
    await tester.pump();
    await tester.ensureVisible(find.text('Validar reserva'));
    await tester.tap(find.text('Validar reserva'));
    await tester.pumpAndSettle();

    expect(find.byType(CodigoReservaScreen), findsNothing);
    expect(api.cuposEnviados, 29);
    expect(find.text('29'), findsOneWidget);
  });
}
