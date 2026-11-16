import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/historial.dart';

/// HU-24: historial de reservas e ingresos del dueño.
/// Lanza una [Exception] con el mensaje del backend si algo falla.
class HistorialService {
  /// Historial del día, la semana o el mes que contiene [fecha].
  /// Sin [parqueaderoId] trae todos los parqueaderos del dueño.
  Future<Historial> consultar({
    required int adminId,
    required PeriodoHistorial periodo,
    required DateTime fecha,
    int? parqueaderoId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/historial/admin/$adminId')
        .replace(
          queryParameters: {
            'periodo': periodo.api,
            'fecha': _iso(fecha),
            if (parqueaderoId != null) 'parqueaderoId': '$parqueaderoId',
          },
        );
    final http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 10));
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
    if (response.statusCode == 200 && body is Map<String, dynamic>) {
      return Historial.fromJson(body);
    }
    if (body is Map && body['mensaje'] != null) {
      throw Exception('${body['mensaje']}');
    }
    throw Exception('Error del servidor (${response.statusCode})');
  }

  static String _iso(DateTime f) =>
      '${f.year.toString().padLeft(4, '0')}-'
      '${f.month.toString().padLeft(2, '0')}-'
      '${f.day.toString().padLeft(2, '0')}';
}
