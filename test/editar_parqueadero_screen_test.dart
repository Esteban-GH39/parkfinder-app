import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/models/parqueadero.dart';
import 'package:parkfinder_app/screens/admin/editar_parqueadero_screen.dart';
import 'package:parkfinder_app/services/api_service.dart';

/// Servicio falso: evita llamadas reales al backend y deja ver con qué campos
/// se invocó la actualización.
class _ApiServiceFalso extends ApiService {
  _ApiServiceFalso({this.respuesta, this.historial = const []});

  final Map<String, dynamic>? respuesta;
  final List<dynamic> historial;

  Map<String, dynamic>? camposEnviados;
  int? idEnviado;
  int vecesLlamado = 0;

  @override
  Future<Map<String, dynamic>> actualizarParqueadero(
    int id,
    Map<String, dynamic> campos,
  ) async {
    vecesLlamado++;
    idEnviado = id;
    camposEnviados = campos;
    return respuesta ??
        {
          'success': true,
          'data': [
            {'campo': 'nombre', 'valorAnterior': 'x', 'valorNuevo': 'y'},
          ],
        };
  }

  @override
  Future<List<dynamic>> obtenerHistorial(int id) async => historial;
}

Parqueadero parqueaderoDePrueba() => Parqueadero(
  id: 7,
  nombre: 'Parqueadero Centro',
  direccion: 'Calle 53 #10-20',
  zona: 'Chapinero',
  nombrePropietario: 'Laura Gómez',
  capacidadTotal: 50,
  tarifaHora: 3000,
  tarifaDia: 20000,
  tarifaNoche: 15000,
  horaInicio: '07:00:00',
  horaFin: '20:00:00',
);

void main() {
  Future<void> montar(WidgetTester tester, _ApiServiceFalso api) async {
    // El formulario tiene 10 campos: con la pantalla de prueba por defecto
    // (800x600) el botón de guardar queda fuera de vista.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: EditarParqueaderoScreen(
        parqueadero: parqueaderoDePrueba(),
        apiService: api,
      )),
    );
  }

  testWidgets('precarga el formulario con los datos actuales', (tester) async {
    await montar(tester, _ApiServiceFalso());

    expect(find.text('Parqueadero Centro'), findsOneWidget);
    expect(find.text('Chapinero'), findsOneWidget);
    expect(find.text('Calle 53 #10-20'), findsOneWidget);
    expect(find.text('Laura Gómez'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('07:00:00'), findsOneWidget);
    expect(find.text('20:00:00'), findsOneWidget);
  });

  testWidgets('no permite dejar el nombre vacío', (tester) async {
    final api = _ApiServiceFalso();
    await montar(tester, api);

    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();

    expect(find.text('Requerido'), findsOneWidget);
    expect(api.vecesLlamado, 0, reason: 'no debe llamar al backend si falla la validación');
  });

  testWidgets('no permite una capacidad negativa', (tester) async {
    final api = _ApiServiceFalso();
    await montar(tester, api);

    await tester.enterText(find.byType(TextFormField).at(4), '-10');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();

    expect(find.text('No puede ser negativo'), findsOneWidget);
    expect(api.vecesLlamado, 0);
  });

  for (final (nombre, indice) in [
    ('por hora', 5),
    ('por día', 6),
    ('por noche', 7),
  ]) {
    testWidgets('rechaza una tarifa $nombre negativa', (tester) async {
      final api = _ApiServiceFalso();
      await montar(tester, api);

      await tester.enterText(find.byType(TextFormField).at(indice), '-100');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pump();

      expect(find.text('No puede ser negativo'), findsOneWidget);
      expect(api.vecesLlamado, 0);
    });
  }

  testWidgets('rechaza una hora con formato inválido', (tester) async {
    final api = _ApiServiceFalso();
    await montar(tester, api);

    await tester.enterText(find.byType(TextFormField).at(8), '25:99');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();

    expect(find.text('Formato esperado: HH:mm'), findsOneWidget);
    expect(api.vecesLlamado, 0);
  });

  testWidgets(
    'envía al backend las claves del DTO (zona, tarifas, horaFinal), no las de la entidad',
    (tester) async {
      final api = _ApiServiceFalso();
      await montar(tester, api);

      await tester.enterText(find.byType(TextFormField).at(0), 'Parqueadero Norte');
      await tester.enterText(find.byType(TextFormField).at(4), '80');
      await tester.enterText(find.byType(TextFormField).at(5), '3500');
      await tester.enterText(find.byType(TextFormField).at(6), '25000');
      await tester.enterText(find.byType(TextFormField).at(7), '18000');
      await tester.enterText(find.byType(TextFormField).at(8), '08:00');
      await tester.enterText(find.byType(TextFormField).at(9), '21:00');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(api.idEnviado, 7);
      expect(api.camposEnviados?['nombre'], 'Parqueadero Norte');
      expect(api.camposEnviados?['capacidadTotal'], 80);
      expect(api.camposEnviados?['tarifaHora'], 3500);
      expect(api.camposEnviados?['tarifaDia'], 25000);
      expect(api.camposEnviados?['tarifaNoche'], 18000);
      // El DTO de edición usa "horaFinal", no "horaFin" (nombre de la entidad).
      expect(api.camposEnviados?['horaFinal'], '21:00');
      expect(api.camposEnviados?.containsKey('horaFin'), isFalse);
      // Claves viejas que ya no existen en el backend.
      expect(api.camposEnviados?.containsKey('ubicacion'), isFalse);
      expect(api.camposEnviados?.containsKey('tarifa'), isFalse);
    },
  );

  testWidgets('un campo de texto vacío se envía como null, no como cadena vacía',
      (tester) async {
    final api = _ApiServiceFalso();
    await montar(tester, api);

    await tester.enterText(find.byType(TextFormField).at(2), ''); // Dirección
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(api.camposEnviados?['direccion'], isNull);
  });

  testWidgets('avisa cuando no hubo cambios que guardar', (tester) async {
    final api = _ApiServiceFalso(
      respuesta: {'success': true, 'data': <dynamic>[]},
    );
    await montar(tester, api);

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('No hubo cambios que guardar'), findsOneWidget);
  });

  testWidgets('muestra el mensaje específico cuando el backend rechaza el cambio (400)',
      (tester) async {
    // Formato real de ValidationExceptionMapper: el mensaje útil viene en
    // error.mensaje, no en el mensaje genérico de más arriba.
    final api = _ApiServiceFalso(
      respuesta: {
        'success': false,
        'error': 'capacidadTotal: La capacidad no puede ser negativa',
      },
    );
    await montar(tester, api);

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(
      find.text('capacidadTotal: La capacidad no puede ser negativa'),
      findsOneWidget,
    );
  });

  testWidgets('el historial muestra los cambios registrados', (tester) async {
    final api = _ApiServiceFalso(
      historial: [
        {
          'campo': 'tarifaHora',
          'valorAnterior': '3000.0',
          'valorNuevo': '3500.0',
          'fecha': '2026-09-27T18:47:34.661564',
        },
      ],
    );
    await montar(tester, api);

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    expect(find.text('Historial de cambios'), findsOneWidget);
    expect(find.text('tarifaHora'), findsOneWidget);
    expect(find.text('3000.0 → 3500.0'), findsOneWidget);
  });

  testWidgets('el historial avisa cuando está vacío', (tester) async {
    await montar(tester, _ApiServiceFalso(historial: const []));

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    expect(find.text('Sin cambios registrados'), findsOneWidget);
  });
}
