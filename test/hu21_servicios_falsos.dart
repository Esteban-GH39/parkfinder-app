import 'dart:async';

import 'package:parkfinder_app/models/comprobante.dart';
import 'package:parkfinder_app/models/parqueadero.dart';
import 'package:parkfinder_app/services/comprobante_service.dart';
import 'package:parkfinder_app/services/parqueadero_service.dart';

/// HU-21: servicios falsos para probar la gestión de cupos sin backend.

/// Servicio falso de parqueaderos: devuelve el listado configurado y deja ver
/// con qué datos se actualizaron los cupos.
class ParqueaderoServiceFalso extends ParqueaderoService {
  ParqueaderoServiceFalso({
    this.parqueaderos = const [],
    this.errorListar,
    this.errorActualizar,
    this.respuestaActualizar,
  });

  List<Parqueadero> parqueaderos;
  Object? errorListar;
  Object? errorActualizar;

  /// Si se asigna, la actualización queda esperando hasta completarlo.
  Completer<bool>? respuestaActualizar;

  int vecesListado = 0;
  int? idAdminListado;

  int vecesActualizado = 0;
  int? idParqueaderoEnviado;
  int? idAdminEnviado;
  int? cuposEnviados;

  @override
  Future<List<Parqueadero>> listarPorAdmin(int idAdmin) async {
    vecesListado++;
    idAdminListado = idAdmin;
    if (errorListar != null) throw errorListar!;
    return parqueaderos;
  }

  @override
  Future<bool> actualizarCuposDisponibles({
    required int idParqueadero,
    required int idAdmin,
    required int nuevosCupos,
  }) async {
    vecesActualizado++;
    idParqueaderoEnviado = idParqueadero;
    idAdminEnviado = idAdmin;
    cuposEnviados = nuevosCupos;
    if (errorActualizar != null) throw errorActualizar!;
    if (respuestaActualizar != null) return respuestaActualizar!.future;
    return true;
  }
}

/// Servicio falso de comprobantes: devuelve el comprobante configurado o
/// lanza el error indicado.
class ComprobanteServiceFalso extends ComprobanteService {
  ComprobanteServiceFalso({this.comprobante, this.error, this.respuesta});

  Comprobante? comprobante;
  Object? error;

  /// Si se asigna, la consulta queda esperando hasta completarlo.
  Completer<Comprobante>? respuesta;

  int vecesConsultado = 0;
  int? idConsultado;

  @override
  Future<Comprobante> obtenerPorId(int idComprobante) async {
    vecesConsultado++;
    idConsultado = idComprobante;
    if (error != null) throw error!;
    if (respuesta != null) return respuesta!.future;
    return comprobante!;
  }
}

Parqueadero parqueaderoDePrueba({
  int id = 7,
  String nombre = 'Parqueadero Centro',
  int capacidadTotal = 50,
  int cuposDisponibles = 30,
}) =>
    Parqueadero(
      id: id,
      nombre: nombre,
      zona: 'Chapinero',
      direccion: 'Calle 53 #10-20',
      representante: 'Laura Gómez',
      capacidadTotal: capacidadTotal,
      cuposDisponiblesApi: cuposDisponibles,
      fk_parqueadero_admin: 3,
    );

Comprobante comprobanteDePrueba({
  int id = 15,
  String? estado = 'APROBADO',
  int parqueaderoId = 7,
}) =>
    Comprobante(
      id: id,
      fechaGenerado: '2026-10-28',
      valorPago: 12000,
      medioPago: 'NEQUI',
      estadoTransaccion: estado,
      fkComprobanteCliente: 4,
      fkComprobanteParqueadero: parqueaderoId,
    );
