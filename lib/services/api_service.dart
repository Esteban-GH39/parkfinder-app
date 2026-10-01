import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/cliente.dart';
import '../models/parqueadero.dart';

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

  /// HU-19: el administrador edita su parqueadero.
  ///
  /// Devuelve {'success': true, 'data': ...} o {'success': false, 'error': ...}
  /// siguiendo el mismo formato que [registrarCliente].
  Future<Map<String, dynamic>> actualizarParqueadero(
    int id,
    Map<String, dynamic> campos,
  ) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/parqueaderos/$id');
      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(campos),
          )
          .timeout(const Duration(seconds: 10));

      if (response.body.isEmpty) {
        return {
          'success': false,
          'error':
              'El servidor respondió vacío (status ${response.statusCode})',
        };
      }

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': body};
      }
      return {'success': false, 'error': _mensajeDeErrorApi(body)};
    } catch (e) {
      return {
        'success': false,
        'error': 'No se pudo conectar con el servidor: $e',
      };
    }
  }

  /// El backend responde los errores con el formato `ResponseApi`:
  /// `{"mensaje": "...", "error": {"mensaje": "...", "detalles": [...]}}`.
  /// `error.mensaje` trae el detalle específico (ej. qué campo falló la
  /// validación); si no viene, se usa el mensaje genérico de más arriba.
  String _mensajeDeErrorApi(dynamic body) {
    if (body is Map<String, dynamic>) {
      final error = body['error'];
      if (error is Map && error['mensaje'] is String) {
        return error['mensaje'] as String;
      }
      if (body['mensaje'] is String) {
        return body['mensaje'] as String;
      }
    }
    return 'Error desconocido';
  }

  /// HU-19: lista los parqueaderos registrados para elegir cuál editar.
  ///
  /// A diferencia de [buscarParqueaderos] (HU-03), distingue entre "no hay
  /// parqueaderos" y "no se pudo consultar": devuelve
  /// {'success': true, 'data': `List<Parqueadero>`} o {'success': false, 'error': ...}.
  Future<Map<String, dynamic>> listarParqueaderos() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/parqueaderos');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'error': 'No se pudo cargar la lista (status ${response.statusCode})',
        };
      }
      final lista = jsonDecode(response.body) as List<dynamic>;
      return {
        'success': true,
        'data': lista
            .map((e) => Parqueadero.fromJson(e as Map<String, dynamic>))
            .toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'No se pudo conectar con el servidor: $e',
      };
    }
  }

  /// HU-19: historial de trazabilidad de un parqueadero.
  Future<List<dynamic>> obtenerHistorial(int id) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/parqueaderos/$id/historial');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 || response.body.isEmpty) {
        return [];
      }
      return jsonDecode(response.body) as List<dynamic>;
    } catch (e) {
      return [];
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
