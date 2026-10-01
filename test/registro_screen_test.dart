import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/screens/cliente/registro_screen.dart';

/// Pruebas de la pantalla de registro (HU-01).
///
/// Solo cubren la validación local del formulario, que ocurre antes de llamar
/// al backend, así que no necesitan tener la API levantada.
void main() {
  Future<void> montarPantalla(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegistroScreen()));
  }

  testWidgets('muestra el formulario de registro', (tester) async {
    await montarPantalla(tester);

    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Nombre'), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Registrarme'), findsOneWidget);
  });

  testWidgets('con los campos vacíos muestra los errores de cada campo',
      (tester) async {
    await montarPantalla(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Registrarme'));
    await tester.pump();

    expect(find.text('Requerido'), findsOneWidget);
    expect(find.text('Correo inválido'), findsOneWidget);
    expect(find.text('Mínimo 8 caracteres'), findsOneWidget);
  });

  testWidgets('rechaza un correo sin arroba', (tester) async {
    await montarPantalla(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Pérez');
    await tester.enterText(find.byType(TextFormField).at(1), 'correo-malo');
    await tester.enterText(find.byType(TextFormField).at(2), 'clave1234');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Registrarme'));
    await tester.pump();

    expect(find.text('Correo inválido'), findsOneWidget);
  });

  testWidgets('rechaza una contraseña de menos de 8 caracteres',
      (tester) async {
    await montarPantalla(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Pérez');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@correo.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'abc');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Registrarme'));
    await tester.pump();

    expect(find.text('Mínimo 8 caracteres'), findsOneWidget);
  });

  testWidgets('rechaza una contraseña sin números', (tester) async {
    await montarPantalla(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Pérez');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@correo.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'clavesinnumero');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Registrarme'));
    await tester.pump();

    expect(find.text('Debe incluir letra y número'), findsOneWidget);
  });
}
