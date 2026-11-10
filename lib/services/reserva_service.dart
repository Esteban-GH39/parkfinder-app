import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// HU-06: reserva de un cupo con retención temporal.
class ReservaService {
  /// Retiene un cupo del parqueadero. Devuelve `{success, data}` o `{success, error}`.
  Future<Map<String, dynamic>> reservar({
    required int clienteId,
    required int parqueaderoId,
    required DateTime llegada,
    int cantidadCarros = 1,
    int cantidadMotos = 0,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/reservas'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'clienteId': clienteId,
              'parqueaderoId': parqueaderoId,
              'fechaHoraLlegada': _formato(llegada),
              'cantidadCarros': cantidadCarros,
              'cantidadMotos': cantidadMotos,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201) {
        return {'success': true, 'data': body};
      }
      return {
        'success': false,
        'sinCupo': response.statusCode == 409,
        'error': _mensaje(body),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'No se pudo conectar con el servidor. Intenta de nuevo.',
      };
    }
  }

  /// HU-07: reservas retenidas que todavía no vencen, para retomar el pago.
  /// Si falla la consulta devuelve una lista vacía: no debe estorbar la búsqueda.
  Future<List<Map<String, dynamic>>> pendientes(int clienteId) =>
      _lista('/reservas/cliente/$clienteId/pendientes');

  /// Reservas ya pagadas y sin usar, con su código de reserva.
  Future<List<Map<String, dynamic>>> confirmadas(int clienteId) =>
      _lista('/reservas/cliente/$clienteId/confirmadas');

  Future<List<Map<String, dynamic>>> _lista(String ruta) async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}$ruta'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return (body as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// El dueño valida el código: queda anotada la hora y no se puede usar otra vez.
  /// Devuelve `{success, data}` o `{success, error}` (409 si ya se usó o no está confirmada).
  Future<Map<String, dynamic>> validar(int reservaId) async {
    try {
      final response = await http
          .post(Uri.parse('${ApiConfig.baseUrl}/reservas/$reservaId/validar'))
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) return {'success': true, 'data': body};
      return {'success': false, 'error': _mensaje(body)};
    } catch (e) {
      return {
        'success': false,
        'error': 'No se pudo conectar con el servidor. Intenta de nuevo.',
      };
    }
  }

  // El backend espera una fecha sin zona horaria: 2026-10-29T10:00:00
  String _formato(DateTime d) => d.toIso8601String().split('.').first;

  String _mensaje(dynamic body) {
    if (body is Map) {
      final error = body['error'];
      if (error is Map &&
          error['detalles'] is List &&
          (error['detalles'] as List).isNotEmpty) {
        return (error['detalles'] as List).join('\n');
      }
      if (body['mensaje'] != null) return '${body['mensaje']}';
    }
    return 'No se pudo completar la reserva';
  }
}
