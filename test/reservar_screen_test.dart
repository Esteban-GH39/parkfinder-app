import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/screens/cliente/reservar_screen.dart';
import 'package:parkfinder_app/services/reserva_service.dart';

/// Guarda lo que la pantalla le pide al backend, sin red.
class _ReservaServiceFalso extends ReservaService {
  int? carros;
  int? motos;

  @override
  Future<Map<String, dynamic>> reservar({
    required int clienteId,
    required int parqueaderoId,
    required DateTime llegada,
    int cantidadCarros = 1,
    int cantidadMotos = 0,
  }) async {
    carros = cantidadCarros;
    motos = cantidadMotos;
    return {
      'success': true,
      'data': {
        'id': 9,
        'cantidad': cantidadCarros + cantidadMotos,
        'cantidadCarros': cantidadCarros,
        'cantidadMotos': cantidadMotos,
        'fechaHoraLlegada': llegada.toIso8601String(),
        'creadaEn': DateTime.now().toIso8601String(),
        'expiraEn': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      },
    };
  }
}

Map<String, dynamic> _parqueadero({int motos = 4}) => {
  'id': 7,
  'nombre': 'Parqueadero Centro',
  'direccion': 'Calle 53 #10-20',
  'zona': 'Chapinero',
  'tarifaHora': 10000,
  'tarifaHoraMoto': 5000,
  'horaInicio': '07:00:00',
  'horaFin': '23:00:00',
  'cuposDisponibles': 12 + motos,
  'cuposCarros': 12,
  'cuposMotos': motos,
  'capacidadMotos': motos,
};

void main() {
  Future<_ReservaServiceFalso> montar(
    WidgetTester tester,
    Map<String, dynamic> parqueadero,
  ) async {
    final servicio = _ReservaServiceFalso();
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ReservarScreen(
          parqueadero: parqueadero,
          clienteId: 1,
          llegadaInicial: DateTime.now().add(const Duration(days: 1)),
          reservaService: servicio,
        ),
      ),
    );
    return servicio;
  }

  String cantidad(WidgetTester tester, String clave) =>
      (tester.widget(find.byKey(Key(clave))) as Text).data!;

  testWidgets('cada tipo lleva su propio contador: 2 carros y 1 moto', (tester) async {
    final servicio = await montar(tester, _parqueadero());

    expect(cantidad(tester, 'cantidadCarros'), '1');
    expect(cantidad(tester, 'cantidadMotos'), '0');

    await tester.tap(find.byKey(const Key('masCarros'))); // carros: 2
    await tester.tap(find.byKey(const Key('masMotos'))); // motos: 1
    await tester.pump();

    expect(cantidad(tester, 'cantidadCarros'), '2');
    expect(cantidad(tester, 'cantidadMotos'), '1');

    await tester.tap(find.byKey(const Key('botonReservar')));
    await tester.pump();

    expect(servicio.carros, 2);
    expect(servicio.motos, 1);
    expect(find.text('2 carros · 1 moto'), findsOneWidget);
  });

  testWidgets('no deja pedir más motos de las que hay', (tester) async {
    await montar(tester, _parqueadero(motos: 2));

    await tester.tap(find.byKey(const Key('masMotos')));
    await tester.tap(find.byKey(const Key('masMotos')));
    await tester.pump();
    expect(cantidad(tester, 'cantidadMotos'), '2');

    // el botón de más queda deshabilitado: un toque más no cambia nada
    await tester.tap(find.byKey(const Key('masMotos')), warnIfMissed: false);
    await tester.pump();
    expect(cantidad(tester, 'cantidadMotos'), '2');
  });

  testWidgets('un parqueadero sin motos solo muestra el contador de carros', (tester) async {
    await montar(tester, _parqueadero(motos: 0));

    expect(find.byKey(const Key('cantidadCarros')), findsOneWidget);
    expect(find.byKey(const Key('cantidadMotos')), findsNothing);
  });

  testWidgets('no se puede quitar el último cupo', (tester) async {
    await montar(tester, _parqueadero());

    await tester.tap(find.byKey(const Key('menosCarros')), warnIfMissed: false);
    await tester.pump();

    expect(cantidad(tester, 'cantidadCarros'), '1');
  });
}
