import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/models/historial.dart';
import 'package:parkfinder_app/screens/admin/historial_ingresos_screen.dart';
import 'package:parkfinder_app/services/historial_service.dart';

/// HU-24: servicio falso que registra con qué filtros se consultó.
class HistorialServiceFalso extends HistorialService {
  HistorialServiceFalso({this.error});

  final Object? error;
  final consultas =
      <({PeriodoHistorial periodo, DateTime fecha, int? parqueaderoId})>[];

  @override
  Future<Historial> consultar({
    required int adminId,
    required PeriodoHistorial periodo,
    required DateTime fecha,
    int? parqueaderoId,
  }) async {
    consultas.add((
      periodo: periodo,
      fecha: fecha,
      parqueaderoId: parqueaderoId,
    ));
    if (error != null) throw error!;
    return Historial.fromJson({
      'desde': '2026-11-09',
      'hasta': '2026-11-15',
      'ingresosReservas': 3000,
      'ingresosEstadias': 4500,
      'ingresosTotales': 7500,
      'totalReservas': 2,
      'reservasPagadas': 1,
      'vehiculosCobrados': 1,
      'desglose': [
        {
          'fecha': '2026-11-12',
          'reservas': 3000,
          'estadias': 4500,
          'total': 7500,
        },
      ],
      'reservas': [
        {
          'id': 1,
          'parqueaderoNombre': 'Centro',
          'clienteNombre': 'Laura Gómez',
          'cantidad': 1,
          'cantidadMotos': 0,
          'codigoReserva': 40,
          'estado': 'CONFIRMADA',
          'creadaEn': '2026-11-12T09:00:00',
          'montoPagado': 3000,
        },
      ],
      'cobros': [
        {
          'id': 5,
          'parqueaderoNombre': 'Centro',
          'placa': 'ABC123',
          'tipoVehiculo': 'CARRO',
          'ingresoEn': '2026-11-12T17:00:00',
          'salidaEn': '2026-11-12T18:30:00',
          'minutos': 90,
          'valorCobrado': 4500,
        },
      ],
    });
  }
}

void main() {
  Future<HistorialServiceFalso> montar(
    WidgetTester tester, {
    Object? error,
  }) async {
    final servicio = HistorialServiceFalso(error: error);
    await tester.pumpWidget(
      MaterialApp(
        home: HistorialIngresosScreen(
          historialService: servicio,
          adminId: 1,
          hoy: DateTime(2026, 11, 15),
          parqueaderos: const [
            {'id': 7, 'nombre': 'Centro'},
            {'id': 8, 'nombre': 'Norte'},
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return servicio;
  }

  testWidgets('muestra los ingresos totales y por origen del día de hoy', (
    tester,
  ) async {
    final servicio = await montar(tester);

    expect(servicio.consultas.single.periodo, PeriodoHistorial.dia);
    expect(servicio.consultas.single.parqueaderoId, isNull);
    expect(find.text('\$7.500'), findsWidgets);
    expect(find.text('Laura Gómez'), findsOneWidget);
  });

  testWidgets('cambiar a semana o mes vuelve a consultar con ese periodo', (
    tester,
  ) async {
    final servicio = await montar(tester);

    await tester.tap(find.byKey(const Key('periodo_SEMANA')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('periodo_MES')));
    await tester.pumpAndSettle();

    expect(servicio.consultas.map((c) => c.periodo), [
      PeriodoHistorial.dia,
      PeriodoHistorial.semana,
      PeriodoHistorial.mes,
    ]);
    expect(find.text('Ingresos por día'), findsOneWidget);
  });

  testWidgets('la flecha anterior consulta el periodo previo', (tester) async {
    final servicio = await montar(tester);

    await tester.tap(find.byKey(const Key('periodoAnterior')));
    await tester.pumpAndSettle();

    expect(servicio.consultas.last.fecha, DateTime(2026, 11, 14));
  });

  testWidgets('la pestaña de vehículos muestra los cobros', (tester) async {
    await montar(tester);

    await tester.tap(find.text('Vehículos (1)'));
    await tester.pumpAndSettle();

    expect(find.text('ABC123'), findsOneWidget);
  });

  testWidgets('si el servidor falla muestra el error', (tester) async {
    await montar(
      tester,
      error: Exception('No se pudo conectar con el servidor.'),
    );

    expect(find.text('No se pudo conectar con el servidor.'), findsOneWidget);
  });
}
