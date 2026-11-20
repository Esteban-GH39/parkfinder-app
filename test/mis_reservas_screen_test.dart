import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/screens/cliente/mis_reservas_screen.dart';
import 'package:parkfinder_app/services/reserva_service.dart';
import 'package:parkfinder_app/services/sesion_service.dart';

class _ReservaServiceFalso extends ReservaService {
  _ReservaServiceFalso(this.datos);
  final List<Map<String, dynamic>> datos;

  /// Reservas que se pidió cancelar: `[reservaId, clienteId]`.
  final cancelaciones = <List<int>>[];
  Map<String, dynamic> respuestaCancelar = {'success': true, 'reembolso': 3000};

  @override
  Future<List<Map<String, dynamic>>> historial(int clienteId) async => datos;

  @override
  Future<Map<String, dynamic>> cancelar(int reservaId, int clienteId) async {
    cancelaciones.add([reservaId, clienteId]);
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

  testWidgets('solo la reserva confirmada por usar tiene botón de cancelar', (tester) async {
    await montar(tester, reservas);
    expect(find.byKey(const Key('botonCancelar_1')), findsOneWidget);
    expect(find.byKey(const Key('botonCancelar_2')), findsNothing);
    expect(find.byKey(const Key('botonCancelar_3')), findsNothing);
  });

  testWidgets('cancelar pide confirmación y avisa del reembolso', (tester) async {
    final servicio = await montar(tester, reservas);
    await tester.tap(find.byKey(const Key('botonCancelar_1')));
    await tester.pumpAndSettle();
    expect(find.text('¿Cancelar la reserva?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('botonConfirmarCancelacion')));
    await tester.pumpAndSettle();

    expect(servicio.cancelaciones, [
      [1, 5],
    ]);
    expect(find.textContaining('Te devolvimos \$3.000'), findsOneWidget);
  });

  testWidgets('si el cliente se arrepiente no se cancela nada', (tester) async {
    final servicio = await montar(tester, reservas);
    await tester.tap(find.byKey(const Key('botonCancelar_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botonMantenerReserva')));
    await tester.pumpAndSettle();

    expect(servicio.cancelaciones, isEmpty);
  });

  testWidgets('si el servidor rechaza la cancelación muestra su mensaje', (tester) async {
    final servicio = await montar(tester, reservas);
    servicio.respuestaCancelar = {
      'success': false,
      'error': 'Ya pasó el tiempo límite para cancelar',
    };
    await tester.tap(find.byKey(const Key('botonCancelar_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botonConfirmarCancelacion')));
    await tester.pumpAndSettle();

    expect(find.text('Ya pasó el tiempo límite para cancelar'), findsOneWidget);
  });

  testWidgets('una reserva CANCELADA se muestra como cancelada y entra en Pasadas', (tester) async {
    await montar(tester, [
      {
        'id': 9,
        'estado': 'CANCELADA',
        'parqueaderoNombre': 'Oeste',
        'cantidad': 1,
        'cantidadMotos': 0,
        'fechaHoraLlegada': futuro,
      },
    ]);
    expect(find.text('Cancelada'), findsOneWidget);
    expect(find.text('Vencida'), findsNothing);
    await tester.tap(find.byKey(const Key('filtro_pasadas')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reserva_9')), findsOneWidget);
  });
}
