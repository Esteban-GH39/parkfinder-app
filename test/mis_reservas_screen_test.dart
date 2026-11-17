import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/screens/cliente/mis_reservas_screen.dart';
import 'package:parkfinder_app/services/reserva_service.dart';
import 'package:parkfinder_app/services/sesion_service.dart';

class _ReservaServiceFalso extends ReservaService {
  _ReservaServiceFalso(this.datos);
  final List<Map<String, dynamic>> datos;

  @override
  Future<List<Map<String, dynamic>>> historial(int clienteId) async => datos;
}

void main() {
  final futuro = DateTime.now().add(const Duration(days: 1)).toIso8601String();
  final reservas = <Map<String, dynamic>>[
    {
      'id': 1,
      'estado': 'CONFIRMADA',
      'parqueaderoNombre': 'Centro',
      'codigoReserva': 77,
      'cantidad': 1,
      'cantidadMotos': 0,
      'fechaHoraLlegada': futuro,
    },
    {
      'id': 2,
      'estado': 'EXPIRADA',
      'parqueaderoNombre': 'Norte',
      'cantidad': 1,
      'cantidadMotos': 0,
      'fechaHoraLlegada': futuro,
    },
    {
      'id': 3,
      'estado': 'CONFIRMADA',
      'validadaEn': futuro,
      'parqueaderoNombre': 'Sur',
      'cantidad': 1,
      'cantidadMotos': 0,
      'fechaHoraLlegada': futuro,
    },
  ];

  Future<void> montar(WidgetTester tester, List<Map<String, dynamic>> datos) async {
    SesionService.instancia.iniciar(
      id: 5,
      nombre: 'Ana',
      correo: 'ana@test.com',
      rol: 'CLIENTE',
    );
    await tester.pumpWidget(
      MaterialApp(home: MisReservasScreen(reservaService: _ReservaServiceFalso(datos))),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra todas las reservas y el código de la confirmada', (tester) async {
    await montar(tester, reservas);
    expect(find.byKey(const Key('reserva_1')), findsOneWidget);
    expect(find.byKey(const Key('reserva_2')), findsOneWidget);
    expect(find.byKey(const Key('reserva_3')), findsOneWidget);
    expect(find.byKey(const Key('codigoReserva_1')), findsOneWidget);
  });

  testWidgets('el filtro Pasadas oculta las confirmadas por usar', (tester) async {
    await montar(tester, reservas);
    await tester.tap(find.byKey(const Key('filtro_pasadas')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reserva_1')), findsNothing);
    expect(find.byKey(const Key('reserva_2')), findsOneWidget);
    expect(find.byKey(const Key('reserva_3')), findsOneWidget);
  });

  testWidgets('sin reservas muestra el mensaje vacío', (tester) async {
    await montar(tester, []);
    expect(find.text('Aún no has hecho reservas'), findsOneWidget);
  });
}
