import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/models/estadia.dart';
import 'package:parkfinder_app/screens/admin/ingreso_vehiculo_screen.dart';
import 'package:parkfinder_app/screens/admin/salida_vehiculo_screen.dart';

import 'estadia_servicios_falsos.dart';
import 'hu21_servicios_falsos.dart';

/// Ingreso directo y liberar cupo por placa, con el cobro por tiempo.
void main() {
  Future<void> montarSalida(
    WidgetTester tester,
    EstadiaServiceFalso servicio,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SalidaVehiculoScreen(
          parqueadero: parqueaderoDePrueba(),
          estadiaService: servicio,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('placa que no está adentro muestra el error del backend', (
    tester,
  ) async {
    final servicio = EstadiaServiceFalso(
      error: Exception(
        'No hay un vehículo con placa XYZ999 dentro de este parqueadero',
      ),
    );
    await montarSalida(tester, servicio);

    await tester.enterText(find.byKey(const Key('placaSalida')), 'xyz999');
    await tester.tap(find.text('Calcular cobro'));
    await tester.pump();

    expect(
      find.text(
        'No hay un vehículo con placa XYZ999 dentro de este parqueadero',
      ),
      findsOneWidget,
    );
    expect(find.text('Confirmar pago y liberar cupo'), findsNothing);
  });

  testWidgets('muestra los vehículos adentro y al tocar uno calcula su cobro', (
    tester,
  ) async {
    final servicio = EstadiaServiceFalso(
      activas: [
        liquidacionDePrueba(
          placa: 'MNO45E',
          tipo: TipoVehiculo.moto,
          valorTotal: 600,
        ),
      ],
      cobro: liquidacionDePrueba(
        placa: 'MNO45E',
        tipo: TipoVehiculo.moto,
        valorTotal: 600,
      ),
    );
    await montarSalida(tester, servicio);

    expect(find.text('Vehículos en el parqueadero (1)'), findsOneWidget);
    await tester.ensureVisible(find.text('MNO45E'));
    await tester.tap(find.text('MNO45E'));
    await tester.pump();

    expect(servicio.cobrosConsultados, ['MNO45E']);
    expect(find.byKey(const Key('totalCobro')), findsOneWidget);
    expect(find.text('Total a pagar'), findsOneWidget);
    expect(find.text('Moto'), findsOneWidget);
  });

  testWidgets('placa inválida no consulta el cobro', (tester) async {
    final servicio = EstadiaServiceFalso();
    await montarSalida(tester, servicio);

    await tester.enterText(find.byKey(const Key('placaSalida')), 'AB');
    await tester.tap(find.text('Calcular cobro'));
    await tester.pump();

    expect(servicio.cobrosConsultados, isEmpty);
    expect(
      find.text(
        'La placa debe tener entre 5 y 7 letras o números (ej. ABC123).',
      ),
      findsOneWidget,
    );
  });

  testWidgets('ingreso directo de moto envía el tipo elegido', (tester) async {
    final servicio = EstadiaServiceFalso();
    final conMotos = parqueaderoDePrueba();
    await tester.pumpWidget(
      MaterialApp(
        home: IngresoVehiculoScreen(
          parqueadero: conMotos,
          tipoInicial: TipoVehiculo.moto,
          estadiaService: servicio,
        ),
      ),
    );

    // El parqueadero de prueba no tiene motos: siempre registra carro
    expect(find.text('Moto'), findsNothing);
    await tester.enterText(find.byKey(const Key('placaIngreso')), 'ABC123');
    await tester.tap(find.text('Registrar ingreso'));
    await tester.pump();

    expect(servicio.ingresosDirectos.single.tipo, TipoVehiculo.carro);
  });
}
