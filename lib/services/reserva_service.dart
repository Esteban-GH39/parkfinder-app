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
