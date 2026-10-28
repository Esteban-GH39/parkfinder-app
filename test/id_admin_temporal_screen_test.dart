import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/screens/admin/id_admin_temporal_screen.dart';
import 'package:parkfinder_app/screens/admin/listar_parqueaderos_screen.dart';

/// HU-21: ingreso temporal del administrador por su id.
void main() {
  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: IngresarAdminScreen()));
  }

  testWidgets('muestra el campo del id y el botón', (tester) async {
    await montar(tester);

    expect(find.text('Ingreso administrador'), findsOneWidget);
    expect(find.text('ID del administrador'), findsOneWidget);
    expect(find.text('Ver mis parqueaderos'), findsOneWidget);
  });

  testWidgets('no permite continuar sin id', (tester) async {
    await montar(tester);

    await tester.tap(find.text('Ver mis parqueaderos'));
    await tester.pump();

    expect(find.text('Requerido'), findsOneWidget);
    expect(find.byType(ListarParqueaderosScreen), findsNothing);
  });

  testWidgets('solo acepta dígitos en el id', (tester) async {
    await montar(tester);

    await tester.enterText(find.byType(TextFormField), 'a1b2');

    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('con un id válido abre el listado de ese administrador',
      (tester) async {
    await montar(tester);

    await tester.enterText(find.byType(TextFormField), '3');
    await tester.tap(find.text('Ver mis parqueaderos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final listado = tester.widget<ListarParqueaderosScreen>(
      find.byType(ListarParqueaderosScreen),
    );
    expect(listado.idAdmin, 3);
  });
}
