import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/estadia.dart';

/// Ingreso y salida de vehículos por placa, con el cobro por tiempo.
/// Cada método lanza una [Exception] con el mensaje del backend si algo falla.
class EstadiaService {
  static const _json = {'Content-Type': 'application/json; charset=utf-8'};
  static const _espera = Duration(seconds: 10);

  /// Ingreso directo: guarda la placa y la hora, y descuenta un cupo del tipo.
  Future<Estadia> ingresoDirecto({
    required int parqueaderoId,
    required int adminId,
    required String placa,
    required TipoVehiculo tipo,
  }) async {
    final body = await _enviar(
      () => http.post(
        Uri.parse('${ApiConfig.baseUrl}/estadias/ingreso'),
        headers: _json,
        body: jsonEncode({
          'parqueaderoId': parqueaderoId,
          'adminId': adminId,
          'placa': placa,
          'tipoVehiculo': tipo.api,
        }),
      ),
      201,
    );
    return Estadia.fromJson(body as Map<String, dynamic>);
  }

  /// Ingreso con código de reserva: valida el código y guarda la placa de cada
  /// vehículo. No descuenta cupos (ya se descontaron al reservar).
  Future<List<Estadia>> ingresoConReserva({
    required int reservaId,
    required int parqueaderoId,
    required int adminId,
    required List<({String placa, TipoVehiculo tipo})> vehiculos,
  }) async {
    final body = await _enviar(
      () => http.post(
        Uri.parse('${ApiConfig.baseUrl}/estadias/ingreso-reserva'),
        headers: _json,
        body: jsonEncode({
          'reservaId': reservaId,
          'parqueaderoId': parqueaderoId,
          'adminId': adminId,
          'vehiculos': [
            for (final v in vehiculos)
              {'placa': v.placa, 'tipoVehiculo': v.tipo.api},
          ],
        }),
      ),
      201,
    );
    return (body as List)
        .map((e) => Estadia.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cuánto debe pagar hasta ahora, sin liberar el cupo.
  Future<Liquidacion> consultarCobro({
    required int parqueaderoId,
    required int adminId,
    required String placa,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/estadias/cobro').replace(
      queryParameters: {
        'parqueaderoId': '$parqueaderoId',
        'adminId': '$adminId',
        'placa': placa,
      },
    );
    final body = await _enviar(() => http.get(uri), 200);
    return Liquidacion.fromJson(body as Map<String, dynamic>);
  }

  /// Registra la salida con la hora actual, cobra y libera el cupo.
  Future<Liquidacion> registrarSalida({
    required int parqueaderoId,
    required int adminId,
    required String placa,
  }) async {
    final body = await _enviar(
      () => http.post(
        Uri.parse('${ApiConfig.baseUrl}/estadias/salida'),
        headers: _json,
        body: jsonEncode({
          'parqueaderoId': parqueaderoId,
          'adminId': adminId,
          'placa': placa,
        }),
      ),
      200,
    );
    return Liquidacion.fromJson(body as Map<String, dynamic>);
  }

  /// Vehículos que están dentro del parqueadero, con lo que llevan acumulado.
  Future<List<Liquidacion>> listarActivas({
    required int parqueaderoId,
    required int adminId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/estadias/parqueadero/$parqueaderoId/activas',
    ).replace(queryParameters: {'adminId': '$adminId'});
    final body = await _enviar(() => http.get(uri), 200);
    return (body as List)
        .map((e) => Liquidacion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<dynamic> _enviar(
    Future<http.Response> Function() peticion,
    int esperado,
  ) async {
    final http.Response response;
    try {
      response = await peticion().timeout(_espera);
    } catch (_) {
      throw Exception('No se pudo conectar con el servidor. Intenta de nuevo.');
    }
    final texto = utf8.decode(response.bodyBytes);
    dynamic body;
    try {
      body = texto.isEmpty ? null : jsonDecode(texto);
    } catch (_) {
      body = texto;
    }
    if (response.statusCode == esperado) return body;
    throw Exception(_mensaje(body, response.statusCode));
  }

  String _mensaje(dynamic body, int status) {
    if (body is Map) {
      final error = body['error'];
      if (error is Map &&
          error['detalles'] is List &&
          (error['detalles'] as List).isNotEmpty) {
        return (error['detalles'] as List).join('\n');
      }
      if (body['mensaje'] != null) return '${body['mensaje']}';
      if (error is Map && error['mensaje'] != null) {
        return '${error['mensaje']}';
      }
    }
    if (body is String && body.isNotEmpty) return body;
    return 'Error del servidor ($status)';
  }
}
