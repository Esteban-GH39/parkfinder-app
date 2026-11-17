import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// HU-13: calificación y comentarios de un parqueadero.
class CalificacionService {
  /// Promedio, total y lista de calificaciones del parqueadero. Lanza una excepción si el
  /// servidor falla, para no confundir un error con "sin calificaciones".
  Future<Map<String, dynamic>> resumen(int parqueaderoId) async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/calificaciones/parqueadero/$parqueaderoId'),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('El servidor respondió ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  /// `{puede, yaCalifico}`: puede = completó una reserva en el parqueadero y aún no lo calificó.
  /// Si falla la consulta devuelve que no puede: no debe estorbar el detalle.
  Future<Map<String, dynamic>> permiso(int clienteId, int parqueaderoId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/calificaciones/permiso').replace(
        queryParameters: {
          'clienteId': '$clienteId',
          'parqueaderoId': '$parqueaderoId',
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return {'puede': false, 'yaCalifico': false};
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return {'puede': false, 'yaCalifico': false};
    }
  }

  /// Envía la calificación. Devuelve `{success: true}` o `{success: false, error}`.
  Future<Map<String, dynamic>> calificar({
    required int clienteId,
    required int parqueaderoId,
    required int estrellas,
    String? comentario,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/calificaciones'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'clienteId': clienteId,
              'parqueaderoId': parqueaderoId,
              'estrellas': estrellas,
              'comentario': (comentario == null || comentario.trim().isEmpty)
                  ? null
                  : comentario.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 201) return {'success': true};
      return {'success': false, 'error': _mensaje(response)};
    } catch (_) {
      return {
        'success': false,
        'error': 'No se pudo conectar con el servidor. Intenta de nuevo.',
      };
    }
  }

  String _mensaje(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map) {
        final error = body['error'];
        if (error is Map &&
            error['detalles'] is List &&
            (error['detalles'] as List).isNotEmpty) {
          return (error['detalles'] as List).join('\n');
        }
        if (body['mensaje'] is String) return body['mensaje'] as String;
      }
    } catch (_) {}
    return 'No se pudo enviar la calificación (código ${response.statusCode})';
  }
}
