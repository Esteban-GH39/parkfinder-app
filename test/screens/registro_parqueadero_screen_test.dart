import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/models/parqueadero.dart';
import 'package:parkfinder_app/screens/admin/registrar_parqueadero_screen.dart';
import 'package:parkfinder_app/services/api_service.dart';

// Servicio falso: guarda lo que recibe y responde lo que se le indique.
class _ApiFalso extends ApiService {
  _ApiFalso({Future<Map<String, dynamic>> Function()? respuesta})
      : _respuesta = respuesta ?? (() async => {'success': true});

  final Future<Map<String, dynamic>> Function() _respuesta;
  Parqueadero? recibido;
  int llamadas = 0;

  @override
  Future<Map<String, dynamic>> registrarParqueadero(Parqueadero p) {
    llamadas++;
    recibido = p;
    return _respuesta();
  }
}

//  Ayudas

//El formulario es largo: se agranda la pantalla virtual para que todos los
// campos queden visibles sin hacer scroll.
void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _montar(WidgetTester tester, ApiService api) async {
  _pantallaGrande(tester);
  await tester.pumpWidget(
    MaterialApp(home: RegistroParqueaderoScreen(apiService: api)),
  );
}

/// Abre la pantalla desde otra para poder comprobar el valor con que se cierra.
Future<void> _montarConHost(
    WidgetTester tester,
    ApiService api,
    void Function(bool?) alVolver,
    ) async {
  _pantallaGrande(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final resultado = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegistroParqueaderoScreen(apiService: api),
                  ),
                );
                alVolver(resultado);
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

Finder _campo(String etiqueta) => find.widgetWithText(TextFormField, etiqueta);

Finder get _botonRegistrar => find.text('Registrar parqueadero');

/// Abre el selector de hora y acepta el valor por defecto (08:00).
Future<void> _elegirHora(WidgetTester tester, String etiqueta) async {
  await tester.tap(_campo(etiqueta));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> _llenarFormulario(
    WidgetTester tester, {
      String nombre = '  Parqueadero Central  ',
      String localidad = 'Usaquén',
      String direccion = 'Calle 100 # 15-20',
      String representante = 'Juan Pérez',
      String capacidad = '50',
      String tarifaHora = '2500',
      String tarifaDia = '20000',
      String tarifaNoche = '12000',
    }) async {
  await tester.enterText(_campo('Nombre Parqueadero'), nombre);
  await tester.enterText(_campo('Localidad'), localidad);
  await tester.pump();
  await tester.enterText(_campo('Dirección'), direccion);
  await tester.enterText(_campo('Propietario o representante'), representante);
  await tester.enterText(_campo('Capacidad total'), capacidad);
  await tester.enterText(_campo('Tarifa por hora'), tarifaHora);
  await tester.enterText(_campo('Tarifa por día'), tarifaDia);
  await tester.enterText(_campo('Tarifa por noche'), tarifaNoche);
  await _elegirHora(tester, 'Hora de inicio de atención');
  await _elegirHora(tester, 'Hora final de atención');
}

Future<void> _enviar(WidgetTester tester) async {
  await tester.tap(_botonRegistrar);
  await tester.pumpAndSettle();
}

// Pruebas

void main() {
  group('Textos de la pantalla', () {
    testWidgets('título centrado y etiquetas actualizadas', (tester) async {
      await _montar(tester, _ApiFalso());

      expect(find.text('Registra tu Parqueadero'), findsOneWidget);
      expect(tester.widget<AppBar>(find.byType(AppBar)).centerTitle, isTrue);
      expect(_campo('Nombre Parqueadero'), findsOneWidget);
      expect(_campo('Localidad'), findsOneWidget);
    });
  });

  group('Validaciones generales', () {
    testWidgets('formulario vacío muestra errores y no llama al servicio', (
        tester,
        ) async {
      final api = _ApiFalso();
      await _montar(tester, api);

      await _enviar(tester);

      // nombre, localidad, dirección, representante, capacidad,
      // 3 tarifas y 2 horas
      expect(find.text('Requerido'), findsNWidgets(10));
      expect(api.llamadas, 0);
    });

    testWidgets('capacidad 0 se rechaza', (tester) async {
      final api = _ApiFalso();
      await _montar(tester, api);

      await _llenarFormulario(tester, capacidad: '0');
      await _enviar(tester);

      expect(find.text('Debe ser mayor a 0'), findsOneWidget);
      expect(api.llamadas, 0);
    });

    testWidgets('capacidad y tarifas descartan las letras al escribir', (
        tester,
        ) async {
      await _montar(tester, _ApiFalso());

      await tester.enterText(_campo('Capacidad total'), '5a0');
      await tester.enterText(_campo('Tarifa por hora'), '25a00');
      await tester.pump();

      expect(find.text('50'), findsOneWidget);
      expect(find.text('2500'), findsOneWidget);
    });
  });

  group('Localidad', () {
    testWidgets('al tocar el campo se despliega la lista y se puede elegir', (
        tester,
        ) async {
      await _montar(tester, _ApiFalso());

      await tester.tap(_campo('Localidad'));
      await tester.pumpAndSettle();

      expect(find.text('Usaquén'), findsOneWidget);
      expect(find.text('Chapinero'), findsOneWidget);

      await tester.tap(find.text('Chapinero'));
      await tester.pumpAndSettle();

      // La lista se cierra y el texto queda dentro del campo.
      expect(find.text('Chapinero'), findsOneWidget);
      expect(find.text('Usaquén'), findsNothing);
    });

    testWidgets('al escribir se filtran las opciones', (tester) async {
      await _montar(tester, _ApiFalso());

      await tester.enterText(_campo('Localidad'), 'sub');
      await tester.pumpAndSettle();

      expect(find.text('Suba'), findsOneWidget);
      expect(find.text('Kennedy'), findsNothing);
    });

    testWidgets('una localidad que no es de Bogotá se rechaza', (tester) async {
      final api = _ApiFalso();
      await _montar(tester, api);

      await _llenarFormulario(tester, localidad: 'Medellín');
      await _enviar(tester);

      expect(
        find.text('Selecciona una localidad válida de Bogotá'),
        findsOneWidget,
      );
      expect(api.llamadas, 0);
    });

    // (lo que escribe el usuario, lo que debe recibir el backend)
    const equivalencias = [
      ('usaquen', 'Usaquén'),
      ('  SUBA  ', 'Suba'),
      ('engativa', 'Engativá'),
      ('los martires', 'Los Mártires'),
      ('ciudad bolivar', 'Ciudad Bolívar'),
    ];

    for (final (escrito, oficial) in equivalencias) {
      testWidgets('"$escrito" se acepta y se envía como "$oficial"', (
          tester,
          ) async {
        final api = _ApiFalso();
        await _montarConHost(tester, api, (_) {});

        await _llenarFormulario(tester, localidad: escrito);
        await _enviar(tester);

        expect(api.llamadas, 1);
        expect(api.recibido!.zona, oficial);
      });
    }
  });

  group('Tarifas: cualquier formato numérico llega como double', () {
    // (lo que escribe el usuario, lo que debe recibir el backend)
    const casos = <(String, double)>[
      ('2500', 2500.0),
      ('2500.50', 2500.5),
      ('2500,50', 2500.5),
      ('2.500', 2500.0),
      ('2,500', 2500.0),
      ('2.500,50', 2500.5),
      ('2,500.50', 2500.5),
      ('1.250.000', 1250000.0),
      ('2.5', 2.5),
      ('0,75', 0.75),
    ];

    for (final (escrito, esperado) in casos) {
      testWidgets('"$escrito" se envía como $esperado', (tester) async {
        final api = _ApiFalso();
        await _montarConHost(tester, api, (_) {});

        await _llenarFormulario(
          tester,
          tarifaHora: escrito,
          tarifaDia: escrito,
          tarifaNoche: escrito,
        );
        await _enviar(tester);

        expect(api.llamadas, 1);
        expect(api.recibido!.tarifaHora, isA<double>());
        expect(api.recibido!.tarifaHora, esperado);
        expect(api.recibido!.tarifaDia, esperado);
        expect(api.recibido!.tarifaNoche, esperado);
      });
    }

    testWidgets('un separador suelto no es un número válido', (tester) async {
      final api = _ApiFalso();
      await _montar(tester, api);

      await _llenarFormulario(tester, tarifaHora: '.');
      await _enviar(tester);

      expect(find.text('Debe ser un número válido'), findsOneWidget);
      expect(api.llamadas, 0);
    });
  });

  group('Registro', () {
    testWidgets('con datos válidos envía todo, confirma y cierra con true', (
        tester,
        ) async {
      final api = _ApiFalso();
      bool? resultado;
      await _montarConHost(tester, api, (r) => resultado = r);

      await _llenarFormulario(tester);
      await _enviar(tester);

      // Se envió el parqueadero completo y limpio
      final p = api.recibido!;
      expect(api.llamadas, 1);
      expect(p.nombre, 'Parqueadero Central');
      expect(p.zona, 'Usaquén');
      expect(p.direccion, 'Calle 100 # 15-20');
      expect(p.representante, 'Juan Pérez');
      expect(p.capacidadTotal, 50);
      expect(p.tarifaHora, 2500.0);
      expect(p.tarifaDia, 20000.0);
      expect(p.tarifaNoche, 12000.0);
      expect(p.horaInicio, '08:00');
      expect(p.horaFinal, '08:00');

      // Mensaje de confirmación
      expect(find.text('Registraste tu parqueadero con éxito!'), findsOneWidget);
      expect(resultado, isNull); // aún no se cierra la pantalla

      // Al aceptar, la pantalla se cierra devolviendo true
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(resultado, isTrue);
      expect(find.byType(RegistroParqueaderoScreen), findsNothing);
    });

    testWidgets('si el backend rechaza, muestra el error y no confirma', (
        tester,
        ) async {
      final api = _ApiFalso(
        respuesta: () async => {
          'success': false,
          'error': 'El nombre es requerido',
        },
      );
      await _montar(tester, api);

      await _llenarFormulario(tester);
      await _enviar(tester);

      expect(find.text('El nombre es requerido'), findsOneWidget);
      expect(find.text('Registraste tu parqueadero con éxito!'), findsNothing);
      expect(find.byType(RegistroParqueaderoScreen), findsOneWidget);
    });

    testWidgets('mientras espera muestra el indicador y oculta el botón', (
        tester,
        ) async {
      final completer = Completer<Map<String, dynamic>>();
      final api = _ApiFalso(respuesta: () => completer.future);
      await _montar(tester, api);

      await _llenarFormulario(tester);
      await tester.tap(_botonRegistrar);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(_botonRegistrar, findsNothing);

      completer.complete({'success': false, 'error': 'Fallo de prueba'});
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_botonRegistrar, findsOneWidget);
      expect(find.text('Fallo de prueba'), findsOneWidget);
    });
  });
}