import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/models/parqueadero.dart';
import 'package:parkfinder_app/screens/admin/editar_parqueadero_screen.dart';
import 'package:parkfinder_app/screens/admin/lista_parqueaderos_screen.dart';
import 'package:parkfinder_app/services/api_service.dart';

/// Servicio falso: evita llamadas reales al backend.
class _ApiServiceFalso extends ApiService {
  _ApiServiceFalso(this.respuesta);

  final Map<String, dynamic> respuesta;
  int vecesListado = 0;

  @override
  Future<Map<String, dynamic>> listarParqueaderos() async {
    vecesListado++;
    return respuesta;
  }

  @override
  Future<List<dynamic>> obtenerHistorial(int id) async => [];
}

Parqueadero _parqueadero(int id, String nombre) => Parqueadero(
  id: id,
  nombre: nombre,
  direccion: 'Calle $id',
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
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: ListaParqueaderosScreen(apiService: api)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra los parqueaderos que devuelve el backend', (tester) async {
    final api = _ApiServiceFalso({
      'success': true,
      'data': [_parqueadero(1, 'Parqueadero Centro'), _parqueadero(2, 'Parqueadero Norte')],
    });
    await montar(tester, api);

    expect(find.text('Parqueadero Centro'), findsOneWidget);
    expect(find.text('Parqueadero Norte'), findsOneWidget);
    expect(find.text('Chapinero · Calle 1'), findsOneWidget);
  });

  testWidgets('avisa cuando no hay parqueaderos', (tester) async {
    await montar(tester, _ApiServiceFalso({'success': true, 'data': <Parqueadero>[]}));

    expect(find.text('No hay parqueaderos registrados'), findsOneWidget);
  });

  testWidgets('muestra el error y permite reintentar cuando falla la carga',
      (tester) async {
    final api = _ApiServiceFalso({'success': false, 'error': 'Sin conexión'});
    await montar(tester, api);

    expect(find.text('Sin conexión'), findsOneWidget);
    expect(api.vecesListado, 1);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(api.vecesListado, 2);
  });

  testWidgets('al tocar un parqueadero abre la pantalla de edición con sus datos',
      (tester) async {
    final api = _ApiServiceFalso({
      'success': true,
      'data': [_parqueadero(1, 'Parqueadero Centro')],
    });
    await montar(tester, api);

    await tester.tap(find.text('Parqueadero Centro'));
    await tester.pumpAndSettle();

    expect(find.byType(EditarParqueaderoScreen), findsOneWidget);
    expect(find.text('Editar parqueadero'), findsOneWidget);
    expect(find.text('Calle 1'), findsOneWidget);
  });

  testWidgets('al volver de editar recarga la lista', (tester) async {
    final api = _ApiServiceFalso({
      'success': true,
      'data': [_parqueadero(1, 'Parqueadero Centro')],
    });
    await montar(tester, api);
    expect(api.vecesListado, 1);

    await tester.tap(find.text('Parqueadero Centro'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(EditarParqueaderoScreen))).pop();
    await tester.pumpAndSettle();

    expect(api.vecesListado, 2);
  });
}
