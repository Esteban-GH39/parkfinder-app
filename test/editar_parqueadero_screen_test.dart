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
          'data': {'cambiosRegistrados': 1},
        };
  }

  @override
  Future<List<dynamic>> obtenerHistorial(int id) async => historial;
}

Parqueadero parqueaderoDePrueba() => Parqueadero(
  id: 7,
  nombre: 'Parqueadero Centro',
  zona: 'Chapinero',
  direccion: 'Calle 53 #10-20',
  representante: 'Laura Gómez',
  capacidadTotal: 50,
  cuposOcupados: 20,
  tarifaHora: 3000,
  tarifaDia: 20000,
);

void main() {
  Future<void> montar(WidgetTester tester, _ApiServiceFalso api) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditarParqueaderoScreen(
          parqueadero: parqueaderoDePrueba(),
          apiService: api,
        ),
      ),
    );
  }

  testWidgets('precarga el formulario con los datos actuales', (tester) async {
    await montar(tester, _ApiServiceFalso());

    expect(find.text('Parqueadero Centro'), findsOneWidget);
    expect(find.text('Chapinero'), findsOneWidget);
    expect(find.text('Calle 53 #10-20'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
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

  testWidgets('no permite cupos ocupados mayores a la capacidad',
      (tester) async {
    final api = _ApiServiceFalso();
    await montar(tester, api);

    // Capacidad 50, se intentan 80 ocupados.
    await tester.enterText(find.byType(TextFormField).at(5), '80');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();

    expect(find.text('No puede superar la capacidad (50)'), findsOneWidget);
    expect(api.vecesLlamado, 0);
  });

  testWidgets('rechaza valores negativos en las tarifas', (tester) async {
    final api = _ApiServiceFalso();
    await montar(tester, api);

    await tester.enterText(find.byType(TextFormField).at(6), '-100');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();

    expect(find.text('No puede ser negativo'), findsOneWidget);
    expect(api.vecesLlamado, 0);
  });

  testWidgets('envía los campos editados al backend y confirma', (tester) async {
    final api = _ApiServiceFalso();
    await montar(tester, api);

    await tester.enterText(find.byType(TextFormField).at(0), 'Parqueadero Norte');
    await tester.enterText(find.byType(TextFormField).at(6), '3500');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(api.idEnviado, 7);
    expect(api.camposEnviados?['nombre'], 'Parqueadero Norte');
    expect(api.camposEnviados?['tarifaHora'], 3500);
    expect(find.textContaining('Parqueadero actualizado'), findsOneWidget);
  });

  testWidgets('avisa cuando no hubo cambios que guardar', (tester) async {
    final api = _ApiServiceFalso(
      respuesta: {
        'success': true,
        'data': {'cambiosRegistrados': 0},
      },
    );
    await montar(tester, api);

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('No hubo cambios que guardar'), findsOneWidget);
  });

  testWidgets('muestra el error que devuelve el backend', (tester) async {
    final api = _ApiServiceFalso(
      respuesta: {
        'success': false,
        'error': 'No existe un parqueadero con id 7',
      },
    );
    await montar(tester, api);

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('No existe un parqueadero con id 7'), findsOneWidget);
  });

  testWidgets('el historial muestra los cambios registrados', (tester) async {
    final api = _ApiServiceFalso(
      historial: [
        {
          'campo': 'tarifaHora',
          'valorAnterior': '3000.0',
          'valorNuevo': '3500.0',
          'fecha': '2026-09-21T16:40:00',
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
