import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parkfinder_app/features/users/registro_cliente_screen.dart';
import 'package:parkfinder_app/features/users/usuario_api.dart';

/// Pruebas de HU-01 (registro de cliente) del lado de la app.
///
/// El backend se reemplaza por un cliente HTTP falso, así que estas pruebas
/// corren sin necesidad de tener la API levantada.
void main() {
  Widget montar(UsuarioApi api) {
    return MaterialApp(home: RegistroClienteScreen(api: api));
  }

  UsuarioApi apiQueResponde(http.Response respuesta) {
    return UsuarioApi(
      baseUrl: 'http://test',
      client: MockClient((_) async => respuesta),
    );
  }

  testWidgets('muestra error cuando el nombre está vacío', (tester) async {
    await tester.pumpWidget(montar(apiQueResponde(http.Response('', 201))));

    await tester.tap(find.text('Crear cuenta').last);
    await tester.pumpAndSettle();

    expect(find.text('El nombre es obligatorio'), findsOneWidget);
  });

  testWidgets('muestra error cuando el correo no tiene formato válido',
      (tester) async {
    await tester.pumpWidget(montar(apiQueResponde(http.Response('', 201))));

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Pérez');
    await tester.enterText(find.byType(TextFormField).at(1), 'correo-malo');
    await tester.enterText(find.byType(TextFormField).at(2), 'clave1234');
    await tester.tap(find.text('Crear cuenta').last);
    await tester.pumpAndSettle();

    expect(find.text('El correo no tiene un formato válido'), findsOneWidget);
  });

  testWidgets('muestra error cuando la contraseña no cumple la regla',
      (tester) async {
    await tester.pumpWidget(montar(apiQueResponde(http.Response('', 201))));

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Pérez');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@correo.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'abc');
    await tester.tap(find.text('Crear cuenta').last);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('mínimo 8 caracteres'),
      findsWidgets,
    );
  });

  testWidgets('muestra el error del backend cuando el correo ya existe (409)',
      (tester) async {
    final api = apiQueResponde(
      http.Response(
        jsonEncode({'mensaje': 'Ya existe una cuenta registrada con el correo: ana@example.com'}),
        409,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    await tester.pumpWidget(montar(api));

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Pérez');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'clave1234');
    await tester.tap(find.text('Crear cuenta').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Ya existe una cuenta registrada con este correo'),
      findsOneWidget,
    );
  });

  testWidgets('registra correctamente con datos válidos (201)', (tester) async {
    final api = apiQueResponde(
      http.Response(
        jsonEncode({
          'id': 1,
          'nombre': 'Ana Pérez',
          'email': 'ana@correo.com',
          'rol': 'CLIENTE',
        }),
        201,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    await tester.pumpWidget(montar(api));

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Pérez');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@correo.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'clave1234');
    await tester.tap(find.text('Crear cuenta').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Cuenta creada'), findsOneWidget);
  });
}
