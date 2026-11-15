import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkfinder_app/models/comprobante.dart';
import 'package:parkfinder_app/models/estadia.dart';
import 'package:parkfinder_app/screens/admin/codigo_reserva_screen.dart';

import 'estadia_servicios_falsos.dart';
import 'hu21_servicios_falsos.dart';

/// HU-21: validación del comprobante de pago, placa del vehículo y descuento del cupo.
void main() {
  late ParqueaderoServiceFalso parqueaderos;
  late ComprobanteServiceFalso comprobantes;
  late EstadiaServiceFalso estadias;
  late ReservaServiceFalso reservas;
  int? cuposDevueltos;

  setUp(() {
    parqueaderos = ParqueaderoServiceFalso();
    comprobantes = ComprobanteServiceFalso(comprobante: comprobanteDePrueba());
    estadias = EstadiaServiceFalso();
    reservas = ReservaServiceFalso();
    cuposDevueltos = null;
  });

  /// Abre la pantalla desde otra ruta para poder leer el valor con que cierra.
  Future<void> montar(WidgetTester tester, {int cuposDisponibles = 30}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              cuposDevueltos = await Navigator.push<int>(
                context,
                MaterialPageRoute(
                  builder: (_) => CodigoReservaScreen(
                    parqueadero: parqueaderoDePrueba(),
                    cuposDisponibles: cuposDisponibles,
                    parqueaderoService: parqueaderos,
                    comprobanteService: comprobantes,
                    estadiaService: estadias,
                    reservaService: reservas,
                  ),
                ),
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> validarComprobante(WidgetTester tester, String id) async {
    await tester.enterText(find.byType(TextField), id);
    await tester.tap(find.text('Validar comprobante'));
    await tester.pump();
  }

  Future<void> digitarPlaca(WidgetTester tester, String placa, {int i = 0}) =>
      tester.enterText(find.byKey(Key('placa_$i')), placa);

  Future<void> validarReserva(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Validar reserva'));
    await tester.tap(find.text('Validar reserva'));
  }

  ElevatedButton botonValidarReserva(WidgetTester tester) =>
      tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Validar reserva'),
      );

  testWidgets('muestra el campo del comprobante y la reserva deshabilitada',
      (tester) async {
    await montar(tester);

    expect(find.text('Ingresa el código de reserva'), findsOneWidget);
    expect(find.text('Código de reserva'), findsOneWidget);
    expect(find.text('Validar comprobante'), findsOneWidget);
    expect(botonValidarReserva(tester).onPressed, isNull);
  });

  testWidgets('sin id no consulta el comprobante', (tester) async {
    await montar(tester);

    await tester.tap(find.text('Validar comprobante'));
    await tester.pump();

    expect(comprobantes.vecesConsultado, 0);
    expect(find.text('Ingrese un id de comprobante válido.'), findsOneWidget);
  });

  testWidgets('un comprobante aprobado muestra sus datos y habilita la reserva',
      (tester) async {
    await montar(tester);

    await validarComprobante(tester, '15');

    expect(comprobantes.idConsultado, 15);
    expect(find.text('Código'), findsOneWidget);
    expect(find.text('2026-10-28'), findsOneWidget);
    expect(find.text('\$12000'), findsOneWidget);
    expect(find.text('NEQUI'), findsOneWidget);
    expect(find.text('APROBADO'), findsOneWidget);
    expect(botonValidarReserva(tester).onPressed, isNotNull);
  });

  testWidgets('el estado se compara sin importar mayúsculas ni espacios',
      (tester) async {
    comprobantes.comprobante = comprobanteDePrueba(estado: '  aprobado ');
    await montar(tester);

    await validarComprobante(tester, '15');

    expect(botonValidarReserva(tester).onPressed, isNotNull);
  });

  group('rechaza el comprobante', () {
    Future<void> esperarError(
      WidgetTester tester,
      Comprobante comprobante,
      String mensaje,
    ) async {
      comprobantes.comprobante = comprobante;
      await montar(tester);

      await validarComprobante(tester, '15');

      expect(find.text(mensaje), findsOneWidget);
      expect(find.text('Código'), findsNothing);
      expect(botonValidarReserva(tester).onPressed, isNull);
    }

    testWidgets('si es de otro parqueadero', (tester) async {
      await esperarError(
        tester,
        comprobanteDePrueba(parqueaderoId: 99),
        'El comprobante 15 no pertenece a este parqueadero.',
      );
    });

    testWidgets('si el pago está pendiente', (tester) async {
      await esperarError(
        tester,
        comprobanteDePrueba(estado: 'PENDIENTE'),
        'El pago del comprobante 15 aún está pendiente.',
      );
    });

    testWidgets('si el pago fue rechazado', (tester) async {
      await esperarError(
        tester,
        comprobanteDePrueba(estado: 'rechazado'),
        'El pago del comprobante 15 fue rechazado.',
      );
    });

    testWidgets('si tiene otro estado', (tester) async {
      await esperarError(
        tester,
        comprobanteDePrueba(estado: 'ANULADO'),
        'El comprobante 15 no está aprobado (estado: ANULADO).',
      );
    });

    testWidgets('si no tiene estado', (tester) async {
      await esperarError(
        tester,
        comprobanteDePrueba(estado: null),
        'El comprobante 15 no está aprobado (estado: sin estado).',
      );
    });
  });

  testWidgets('si la consulta falla muestra el error sin "Exception:"',
      (tester) async {
    comprobantes.error = Exception('No existe un comprobante con id 15.');
    await montar(tester);

    await validarComprobante(tester, '15');

    expect(find.text('No existe un comprobante con id 15.'), findsOneWidget);
  });

  testWidgets('mientras consulta muestra el indicador', (tester) async {
    final respuesta = Completer<Comprobante>();
    comprobantes.respuesta = respuesta;
    await montar(tester);

    await validarComprobante(tester, '15');

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Validar comprobante'), findsNothing);

    respuesta.complete(comprobanteDePrueba());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('APROBADO'), findsOneWidget);
  });

  testWidgets('validar la reserva registra la placa, descuenta un cupo y cierra con el nuevo valor',
      (tester) async {
    await montar(tester);

    await validarComprobante(tester, '15');
    expect(find.text('Placa del vehículo'), findsWidgets);
    await digitarPlaca(tester, 'abc123');
    await validarReserva(tester);
    await tester.pumpAndSettle();

    // Sin reserva asociada el backend registra la placa y descuenta el cupo
    expect(estadias.ingresosDirectos.single.placa, 'ABC123');
    expect(estadias.ingresosDirectos.single.tipo, TipoVehiculo.carro);
    expect(parqueaderos.vecesActualizado, 0);
    expect(find.byType(CodigoReservaScreen), findsNothing);
    expect(cuposDevueltos, 29);
  });

  testWidgets('sin placa no valida la reserva', (tester) async {
    await montar(tester);

    await validarComprobante(tester, '15');
    await validarReserva(tester);
    await tester.pump();

    expect(estadias.ingresosDirectos, isEmpty);
    expect(find.text('Digita la placa del vehículo.'), findsOneWidget);
    expect(find.byType(CodigoReservaScreen), findsOneWidget);
  });

  testWidgets('con una placa inválida no valida la reserva', (tester) async {
    await montar(tester);

    await validarComprobante(tester, '15');
    await digitarPlaca(tester, 'AB1');
    await validarReserva(tester);
    await tester.pump();

    expect(estadias.ingresosDirectos, isEmpty);
    expect(
      find.text('La placa debe tener entre 5 y 7 letras o números (ej. ABC123).'),
      findsOneWidget,
    );
  });

  testWidgets('con reserva pide una placa por vehículo y valida el código',
      (tester) async {
    comprobantes.comprobante = Comprobante(
      id: 15,
      estadoTransaccion: 'APROBADO',
      fkComprobanteParqueadero: 7,
      reservaId: 9,
    );
    reservas.reserva = {'cantidad': 2, 'cantidadCarros': 1, 'cantidadMotos': 1};
    await montar(tester);

    await validarComprobante(tester, '15');

    expect(reservas.idConsultado, 9);
    expect(find.text('Placa carro 1'), findsOneWidget);
    expect(find.text('Placa moto 1'), findsOneWidget);

    // Solo llegó el carro: la placa de la moto queda vacía
    await digitarPlaca(tester, 'ABC123');
    await validarReserva(tester);
    await tester.pumpAndSettle();

    final ingreso = estadias.ingresosConReserva.single;
    expect(ingreso.reservaId, 9);
    expect(ingreso.vehiculos.single.placa, 'ABC123');
    expect(ingreso.vehiculos.single.tipo, TipoVehiculo.carro);
    expect(estadias.ingresosDirectos, isEmpty);
    // Los cupos de la reserva ya se habían descontado al reservar
    expect(cuposDevueltos, 30);
  });

  testWidgets('sin cupos disponibles no valida la reserva', (tester) async {
    await montar(tester, cuposDisponibles: 0);

    await validarComprobante(tester, '15');
    await digitarPlaca(tester, 'ABC123');
    await validarReserva(tester);
    await tester.pump();

    expect(parqueaderos.vecesActualizado, 0);
    expect(estadias.ingresosDirectos, isEmpty);
    expect(
      find.text('No hay cupos disponibles para descontar.'),
      findsOneWidget,
    );
    expect(find.byType(CodigoReservaScreen), findsOneWidget);
  });

  testWidgets('si el backend rechaza la reserva se queda en la pantalla',
      (tester) async {
    estadias.error = Exception('El vehículo ABC123 ya está registrado dentro de un parqueadero');
    await montar(tester);

    await validarComprobante(tester, '15');
    await digitarPlaca(tester, 'ABC123');
    await validarReserva(tester);
    await tester.pump();

    expect(
      find.text('El vehículo ABC123 ya está registrado dentro de un parqueadero'),
      findsOneWidget,
    );
    expect(find.byType(CodigoReservaScreen), findsOneWidget);
    expect(cuposDevueltos, isNull);
  });
}
