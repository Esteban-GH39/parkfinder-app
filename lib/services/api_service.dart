import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/cliente.dart';

class ApiService {
  Future<Map<String, dynamic>> registrarCliente(Cliente cliente) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/clientes/registro');
      print('DEBUG: Enviando POST a $url');
      print('DEBUG: Body enviado: ${jsonEncode(cliente.toJson())}');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(cliente.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      print('DEBUG: Headers enviados: ${response.request?.headers}');

      print('DEBUG: Status code: ${response.statusCode}');
      print('DEBUG: Response body: "${response.body}"');
      print('DEBUG: Response body length: ${response.body.length}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'error':
              'El servidor respondió vacío (status ${response.statusCode})',
        };
      }

      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': body};
      }
      return {'success': false, 'error': body['error'] ?? 'Error desconocido'};
    } catch (e) {
      print('DEBUG: Excepción capturada: $e');
      return {
        'success': false,
        'error': 'No se pudo conectar con el servidor: $e',
      };
    }
  }

  Future<List<dynamic>> buscarParqueaderos({String? zona}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/parqueaderos').replace(
        queryParameters: zona != null && zona.isNotEmpty
            ? {'zona': zona}
            : null,
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.body.isEmpty) {
        return [];
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('DEBUG: Error al buscar parqueaderos: $e');
      return [];
    }
  }
}
