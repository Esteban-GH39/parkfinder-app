import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/models/parqueadero.dart';
import 'package:parkfinder_app/screens/admin/codigo_reserva_screen.dart';
import 'package:parkfinder_app/screens/admin/gestion_cupos_parqueadero_screen.dart';
import 'package:parkfinder_app/screens/admin/ingreso_vehiculo_screen.dart';
import 'package:parkfinder_app/screens/admin/salida_vehiculo_screen.dart';

import 'estadia_servicios_falsos.dart';
import 'hu21_servicios_falsos.dart';

/// HU-21: el administrador descuenta o libera cupos de un parqueadero.
void main() {
  Future<void> montar(
    WidgetTester tester,
    ParqueaderoServiceFalso api, {
    Parqueadero? parqueadero,
    ComprobanteServiceFalso? comprobantes,
    EstadiaServiceFalso? estadias,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GestionCuposParqueaderoScreen(
          parqueadero: parqueadero ?? parqueaderoDePrueba(),
          parqueaderoService: api,
          comprobanteService: comprobantes,
          estadiaService: estadias ?? EstadiaServiceFalso(),
        ),
      ),
    );
  }

  Future<void> tocar(WidgetTester tester, String texto) async {
    await tester.ensureVisible(find.text(texto));
    await tester.tap(find.text(texto));
  }

  testWidgets('muestra el parqueadero, la capacidad y los cupos',
      (tester) async {
    await montar(tester, ParqueaderoServiceFalso());

    expect(find.text('Gestión de cupos'), findsOneWidget);
    expect(find.text('Parqueadero Centro'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('Código de reserva'), findsOneWidget);
    expect(find.text('Ingreso directo'), findsOneWidget);
    expect(find.text('Liberar cupo'), findsOneWidget);
    expect(find.text('-1 cupo'), findsOneWidget);
    expect(find.text('+1 cupo'), findsOneWidget);
  });

  testWidgets('el ajuste manual -1 descuenta un cupo', (tester) async {
    final api = ParqueaderoServiceFalso();
    await montar(tester, api);

    await tocar(tester, '-1 cupo');
    await tester.pump();

    expect(api.vecesActualizado, 1);
    expect(api.idParqueaderoEnviado, 7);
    expect(api.idAdminEnviado, 3);
    expect(api.cuposEnviados, 29);
    expect(find.text('29'), findsOneWidget);
    expect(find.text('Cupos actualizados correctamente.'), findsOneWidget);
  });

  testWidgets('el ajuste manual +1 agrega un cupo', (tester) async {
    final api = ParqueaderoServiceFalso();
    await montar(tester, api);

    await tocar(tester, '+1 cupo');
    await tester.pump();

    expect(api.cuposEnviados, 31);
    expect(find.text('31'), findsOneWidget);
  });

  testWidgets('sin cupos el ajuste manual no descuenta', (tester) async {
    final api = ParqueaderoServiceFalso();
    await montar(
      tester,
      api,
      parqueadero: parqueaderoDePrueba(cuposDisponibles: 0),
    );

    await tocar(tester, '-1 cupo');
    await tester.pump();

    expect(api.vecesActualizado, 0);
    expect(
      find.text('No hay cupos disponibles para descontar.'),
      findsOneWidget,
    );
  });

  testWidgets('el ajuste manual no supera la capacidad', (tester) async {
    final api = ParqueaderoServiceFalso();
    await montar(
      tester,
      api,
      parqueadero: parqueaderoDePrueba(cuposDisponibles: 50),
    );

    await tocar(tester, '+1 cupo');
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

    await tocar(tester, '-1 cupo');
    await tester.pump();

    expect(find.text('Parqueadero no encontrado'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('mientras actualiza muestra el indicador y bloquea los botones',
      (tester) async {
    final respuesta = Completer<bool>();
    final api = ParqueaderoServiceFalso(respuestaActualizar: respuesta);
    await montar(tester, api);

    await tocar(tester, '-1 cupo');
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

  testWidgets('al validar una reserva con placa vuelve con los cupos actualizados',
      (tester) async {
    final api = ParqueaderoServiceFalso();
    final estadias = EstadiaServiceFalso();
    await montar(
      tester,
      api,
      comprobantes: ComprobanteServiceFalso(comprobante: comprobanteDePrueba()),
      estadias: estadias,
    );

    await tester.tap(find.text('Código de reserva'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '15');
    await tester.tap(find.text('Validar comprobante'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('placa_0')), 'ABC123');
    await tocar(tester, 'Validar reserva');
    await tester.pumpAndSettle();

    expect(find.byType(CodigoReservaScreen), findsNothing);
    expect(estadias.ingresosDirectos.single.placa, 'ABC123');
    expect(find.text('29'), findsOneWidget);
  });

  testWidgets('ingreso directo registra la placa y descuenta el cupo',
      (tester) async {
    final estadias = EstadiaServiceFalso();
    await montar(tester, ParqueaderoServiceFalso(), estadias: estadias);

    await tocar(tester, 'Ingreso directo');
    await tester.pumpAndSettle();
    expect(find.byType(IngresoVehiculoScreen), findsOneWidget);

    await tester.enterText(find.byKey(const Key('placaIngreso')), 'abc123');
    await tester.tap(find.text('Registrar ingreso'));
    await tester.pumpAndSettle();

    expect(find.byType(IngresoVehiculoScreen), findsNothing);
    expect(estadias.ingresosDirectos.single.placa, 'ABC123');
    expect(find.text('29'), findsOneWidget);
    expect(find.text('Ingreso registrado: ABC123 a las 18:00.'), findsOneWidget);
  });

  testWidgets('liberar cupo calcula el cobro, confirma y suma el cupo',
      (tester) async {
    final estadias = EstadiaServiceFalso();
    await montar(tester, ParqueaderoServiceFalso(), estadias: estadias);

    await tocar(tester, 'Liberar cupo');
    await tester.pumpAndSettle();
    expect(find.byType(SalidaVehiculoScreen), findsOneWidget);

    await tester.enterText(find.byKey(const Key('placaSalida')), 'ABC123');
    await tester.tap(find.text('Calcular cobro'));
    await tester.pump();
    expect(find.text('\$2.250'), findsOneWidget);
    expect(estadias.salidas, isEmpty);

    await tocar(tester, 'Confirmar pago y liberar cupo');
    await tester.pump();
    expect(estadias.salidas, ['ABC123']);
    expect(find.text('Salida registrada. El cupo quedó libre.'), findsOneWidget);

    await tocar(tester, 'Listo');
    await tester.pumpAndSettle();

    expect(find.byType(SalidaVehiculoScreen), findsNothing);
    expect(find.text('31'), findsOneWidget);
  });

  testWidgets('si sale de liberar cupo sin confirmar no cambia los cupos',
      (tester) async {
    await montar(tester, ParqueaderoServiceFalso());

    await tocar(tester, 'Liberar cupo');
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(SalidaVehiculoScreen), findsNothing);
    expect(find.text('30'), findsOneWidget);
  });
}
