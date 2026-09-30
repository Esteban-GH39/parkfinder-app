import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/cliente.dart';

class ApiService {
  Future<Map<String, dynamic>> registrarCliente(Cliente cliente) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/clientes');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(cliente.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      // El backend responde 201 sin cuerpo
      if (response.statusCode == 201) {
        return {'success': true};
      }

      if (response.body.isEmpty) {
        return {
          'success': false,
          'error':
              'El servidor respondió vacío (status ${response.statusCode})',
        };
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return {'success': false, 'error': _extraerMensaje(body)};
    } catch (e) {
      return {
        'success': false,
        'error': 'No se pudo conectar con el servidor: $e',
      };
    }
  }

  String _extraerMensaje(dynamic body) {
    if (body is Map) {
      final error = body['error'];
      if (error is Map &&
          error['detalles'] is List &&
          (error['detalles'] as List).isNotEmpty) {
        return (error['detalles'] as List).join('\n');
      }
      if (body['mensaje'] is String) return body['mensaje'] as String;
    }
    return 'Error desconocido';
  }

  Future<List<dynamic>> buscarParqueaderos({String? zona}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/parqueaderos/buscar').replace(
        queryParameters: (zona != null && zona.trim().isNotEmpty)
            ? {'zona': zona.trim()}
            : null,
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 || response.body.isEmpty) {
        return [];
      }

      return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    } catch (e) {
      print('DEBUG: Error al buscar parqueaderos: $e');
      return [];
    }
  }
}
