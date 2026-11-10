import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// HU-07: pago de una reserva con la pasarela simulada (no mueve dinero real).
class PagoService {
  /// [medio] es TARJETA, PSE o NEQUI y [datos] los campos que pide cada uno.
  /// Devuelve `{success, data}` (data.estado es APROBADO o RECHAZADO) o `{success, error}`.
  Future<Map<String, dynamic>> pagar({
    required int reservaId,
    required String medio,
    required Map<String, String> datos,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/pagos'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'reservaId': reservaId,
              'medioPago': medio,
              'datos': datos,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201) {
        return {'success': true, 'data': body};
      }
      return {'success': false, 'error': _mensaje(body)};
    } catch (e) {
      return {
        'success': false,
        'error': 'No se pudo conectar con el servidor. Intenta de nuevo.',
      };
    }
  }

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
    return 'No se pudo procesar el pago';
  }
}
