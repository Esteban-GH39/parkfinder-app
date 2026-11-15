import 'package:parkfinder_app/models/estadia.dart';
import 'package:parkfinder_app/services/estadia_service.dart';
import 'package:parkfinder_app/services/reserva_service.dart';

/// Servicio falso de ingresos y salidas: deja ver qué se envió y devuelve lo configurado.
class EstadiaServiceFalso extends EstadiaService {
  EstadiaServiceFalso({this.error, this.cobro, this.activas = const []});

  /// Si se asigna, todas las operaciones lanzan este error.
  Object? error;

  /// Lo que devuelve la consulta del cobro (y, cerrado, la salida).
  Liquidacion? cobro;
  List<Liquidacion> activas;

  final List<({String placa, TipoVehiculo tipo})> ingresosDirectos = [];
  final List<
    ({int reservaId, List<({String placa, TipoVehiculo tipo})> vehiculos})
  >
  ingresosConReserva = [];
  final List<String> cobrosConsultados = [];
  final List<String> salidas = [];

  @override
  Future<Estadia> ingresoDirecto({
    required int parqueaderoId,
    required int adminId,
    required String placa,
    required TipoVehiculo tipo,
  }) async {
    ingresosDirectos.add((placa: placa, tipo: tipo));
    if (error != null) throw error!;
    return Estadia(
      id: 1,
      parqueaderoId: parqueaderoId,
      placa: placa,
      tipoVehiculo: tipo,
      ingresoEn: DateTime(2026, 11, 15, 18, 0),
    );
  }

  @override
  Future<List<Estadia>> ingresoConReserva({
    required int reservaId,
    required int parqueaderoId,
    required int adminId,
    required List<({String placa, TipoVehiculo tipo})> vehiculos,
  }) async {
    ingresosConReserva.add((reservaId: reservaId, vehiculos: vehiculos));
    if (error != null) throw error!;
    return [
      for (final v in vehiculos)
        Estadia(
          id: 1,
          parqueaderoId: parqueaderoId,
          reservaId: reservaId,
          placa: v.placa,
          tipoVehiculo: v.tipo,
        ),
    ];
  }

  @override
  Future<Liquidacion> consultarCobro({
    required int parqueaderoId,
    required int adminId,
    required String placa,
  }) async {
    cobrosConsultados.add(placa);
    if (error != null) throw error!;
    return cobro ?? liquidacionDePrueba(placa: placa);
  }

  @override
  Future<Liquidacion> registrarSalida({
    required int parqueaderoId,
    required int adminId,
    required String placa,
  }) async {
    salidas.add(placa);
    if (error != null) throw error!;
    return liquidacionDePrueba(
      placa: placa,
      tipo: cobro?.tipoVehiculo ?? TipoVehiculo.carro,
      valorTotal: cobro?.valorTotal ?? 2250,
      cerrada: true,
    );
  }

  @override
  Future<List<Liquidacion>> listarActivas({
    required int parqueaderoId,
    required int adminId,
  }) async => activas;
}

/// Servicio falso de reservas: devuelve la reserva configurada.
class ReservaServiceFalso extends ReservaService {
  ReservaServiceFalso({this.reserva});

  Map<String, dynamic>? reserva;
  int? idConsultado;

  @override
  Future<Map<String, dynamic>> obtener(int reservaId) async {
    idConsultado = reservaId;
    if (reserva == null) return {'success': false, 'error': 'No existe'};
    return {'success': true, 'data': reserva};
  }
}

Liquidacion liquidacionDePrueba({
  String placa = 'ABC123',
  TipoVehiculo tipo = TipoVehiculo.carro,
  double valorTotal = 2250,
  int minutos = 45,
  bool cerrada = false,
}) => Liquidacion(
  estadiaId: 3,
  placa: placa,
  tipoVehiculo: tipo,
  ingresoEn: DateTime(2026, 11, 15, 10, 0),
  salidaEn: DateTime(2026, 11, 15, 10, 45),
  cerrada: cerrada,
  minutos: minutos,
  minutosDiurnos: minutos,
  tarifaHora: 3000,
  tarifaDia: 25000,
  tarifaNoche: 15000,
  valorMinuto: 50,
  valorTotal: valorTotal,
);
