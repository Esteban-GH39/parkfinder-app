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

      if (response.statusCode == 201) {
        return {'success': true};
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

  /// HU-03: busca parqueaderos por zona (texto parcial). Sin zona devuelve todos.
  /// Lanza una excepción si no se puede conectar, para no confundir un error
  /// con "sin resultados".
  Future<List<dynamic>> buscarParqueaderos({String? zona}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/parqueaderos').replace(
      queryParameters: (zona != null && zona.trim().isNotEmpty)
          ? {'zona': zona.trim()}
          : null,
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception(
        'El servidor respondió ${response.statusCode}: ${response.body}',
      );
    }
    if (response.body.isEmpty) return [];
    return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
  }

  /// HU-03: zonas existentes para elegir en el buscador. Si falla devuelve vacío
  /// (el usuario aún puede escribir la zona).
  Future<List<String>> obtenerZonas() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/parqueaderos/zonas');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 || response.body.isEmpty) return [];
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return data.map((z) => z.toString()).toList();
    } catch (_) {
      return [];
    }
  }
}
