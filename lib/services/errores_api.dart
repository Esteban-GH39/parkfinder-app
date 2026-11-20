import 'dart:convert';

import 'package:http/http.dart' as http;

/// Saca un mensaje legible del cuerpo de error del backend (formato común o validaciones).
String mensajeDeError(dynamic body, String porDefecto) {
  if (body is Map) {
    final error = body['error'];
    if (error is Map && error['detalles'] is List && (error['detalles'] as List).isNotEmpty) {
      return (error['detalles'] as List).join('\n');
    }
    if (body['mensaje'] != null) return '${body['mensaje']}';
  }
  return porDefecto;
}

/// Hace una petición y devuelve `{success, data, headers}` si el código está en [exito],
/// o `{success: false, status, error}` si no. Nunca lanza: sin conexión también es un `error`.
Future<Map<String, dynamic>> llamar(
  Future<http.Response> Function() peticion, {
  Set<int> exito = const {200},
  String porDefecto = 'No se pudo completar la operación',
}) async {
  try {
    final r = await peticion().timeout(const Duration(seconds: 10));
    dynamic body;
    if (r.bodyBytes.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(r.bodyBytes));
      } catch (_) {
        body = null; // no era JSON
      }
    }
    if (exito.contains(r.statusCode)) {
      return {'success': true, 'data': body, 'headers': r.headers};
    }
    return {
      'success': false,
      'status': r.statusCode,
      'error': mensajeDeError(body, porDefecto),
    };
  } catch (_) {
    return {
      'success': false,
      'error': 'No se pudo conectar con el servidor. Intenta de nuevo.',
    };
  }
}

const cabecerasJson = {'Content-Type': 'application/json; charset=utf-8'};
