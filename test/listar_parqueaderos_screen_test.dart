import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/screens/admin/gestion_cupos_parqueadero_screen.dart';
import 'package:parkfinder_app/screens/admin/listar_parqueaderos_screen.dart';

import 'hu21_servicios_falsos.dart';

/// HU-21: listado de los parqueaderos del administrador.
void main() {
  Future<void> montar(WidgetTester tester, ParqueaderoServiceFalso api) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListarParqueaderosScreen(idAdmin: 3, parqueaderoService: api),
      ),
    );
  }

  testWidgets('consulta los parqueaderos del administrador recibido',
      (tester) async {
    final api = ParqueaderoServiceFalso();
    await montar(tester, api);
    await tester.pumpAndSettle();

    expect(api.vecesListado, 1);
    expect(api.idAdminListado, 3);
  });

  testWidgets('mientras carga muestra el indicador', (tester) async {
    await montar(tester, ParqueaderoServiceFalso());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('muestra cada parqueadero con sus datos', (tester) async {
    final api = ParqueaderoServiceFalso(
      parqueaderos: [
        parqueaderoDePrueba(),
        parqueaderoDePrueba(id: 8, nombre: 'Parqueadero Norte'),
      ],
    );
    await montar(tester, api);
    await tester.pumpAndSettle();

    expect(find.text('Mis parqueaderos'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.text('Parqueadero Centro'), findsOneWidget);
    expect(find.text('Parqueadero Norte'), findsOneWidget);
    expect(
      find.text(
        'Calle 53 #10-20\nCapacidad total: 50 · Encargado: Laura Gómez',
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('sin nombre ni dirección usa textos por defecto',
      (tester) async {
    final api = ParqueaderoServiceFalso(
      parqueaderos: [parqueaderoDePrueba(nombre: '')],
    );
    await montar(tester, api);
    await tester.pumpAndSettle();

    expect(find.text('Parqueadero 7'), findsOneWidget);
  });

  testWidgets('sin parqueaderos muestra el mensaje vacío', (tester) async {
    await montar(tester, ParqueaderoServiceFalso());
    await tester.pumpAndSettle();

    expect(find.text('Sin parqueaderos registrados'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('si falla la consulta muestra el error y permite reintentar',
      (tester) async {
    final api = ParqueaderoServiceFalso(
      errorListar: Exception('Sin conexión'),
    );
    await montar(tester, api);
    await tester.pumpAndSettle();

    expect(find.text('Exception: Sin conexión'), findsOneWidget);

    api
      ..errorListar = null
      ..parqueaderos = [parqueaderoDePrueba()];
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(api.vecesListado, 2);
    expect(find.text('Parqueadero Centro'), findsOneWidget);
  });

  testWidgets('al tocar un parqueadero abre su gestión de cupos',
      (tester) async {
    final api = ParqueaderoServiceFalso(parqueaderos: [parqueaderoDePrueba()]);
    await montar(tester, api);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Parqueadero Centro'));
    await tester.pumpAndSettle();

    final gestion = tester.widget<GestionCuposParqueaderoScreen>(
      find.byType(GestionCuposParqueaderoScreen),
    );
    expect(gestion.parqueadero.id, 7);
    expect(gestion.parqueaderoService, same(api));
  });
}
