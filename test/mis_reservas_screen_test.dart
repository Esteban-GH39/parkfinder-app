import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/screens/cliente/mis_reservas_screen.dart';
import 'package:parkfinder_app/services/reserva_service.dart';
import 'package:parkfinder_app/services/sesion_service.dart';

class _ReservaServiceFalso extends ReservaService {
  _ReservaServiceFalso(this.datos);
  final List<Map<String, dynamic>> datos;

  /// Lo que responde cancelar; guarda a qué reserva se lo pidieron.
  Map<String, dynamic> respuestaCancelar = {'success': true};
  int? canceladaId;

  @override
  Future<List<Map<String, dynamic>>> historial(int clienteId) async => datos;

  @override
  Future<Map<String, dynamic>> cancelar(int reservaId, int clienteId) async {
    canceladaId = reservaId;
    return respuestaCancelar;
  }
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
      'parqueaderoId': 3,
      'parqueaderoNombre': 'Sur',
      'cantidad': 1,
      'cantidadMotos': 0,
      'fechaHoraLlegada': futuro,
    },
  ];

  Future<_ReservaServiceFalso> montar(WidgetTester tester, List<Map<String, dynamic>> datos) async {
    final servicio = _ReservaServiceFalso(datos);
    SesionService.instancia.iniciar(
      id: 5,
      nombre: 'Ana',
      correo: 'ana@test.com',
      rol: 'CLIENTE',
    );
    await tester.pumpWidget(
      MaterialApp(home: MisReservasScreen(reservaService: servicio)),
    );
    await tester.pumpAndSettle();
    return servicio;
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

  testWidgets('HU-10: cancelar una confirmada pide confirmación y avisa', (tester) async {
    final servicio = await montar(tester, reservas);

    await tester.tap(find.byKey(const Key('botonCancelar_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('noCancelar')));
    await tester.pumpAndSettle();
    expect(servicio.canceladaId, isNull);

    await tester.tap(find.byKey(const Key('botonCancelar_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('siCancelar')));
    await tester.pumpAndSettle();
    expect(servicio.canceladaId, 1);
    expect(find.text('Reserva cancelada'), findsOneWidget);
  });

  testWidgets('HU-10: si pasó el límite muestra el motivo del servidor', (tester) async {
    final servicio = await montar(tester, reservas);
    servicio.respuestaCancelar = {
      'success': false,
      'error': 'Ya pasó el tiempo límite para cancelar',
    };

    await tester.tap(find.byKey(const Key('botonCancelar_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('siCancelar')));
    await tester.pumpAndSettle();
    expect(find.text('Ya pasó el tiempo límite para cancelar'), findsOneWidget);
  });

  testWidgets('HU-10: una reserva CANCELADA aparece como Cancelada, sin botón', (tester) async {
    await montar(tester, [
      {
        'id': 9,
        'estado': 'CANCELADA',
        'parqueaderoNombre': 'Centro',
        'cantidad': 1,
        'cantidadMotos': 0,
        'fechaHoraLlegada': futuro,
      },
    ]);
    expect(find.text('Cancelada'), findsWidgets);
    expect(find.byKey(const Key('botonCancelar_9')), findsNothing);
  });
}
