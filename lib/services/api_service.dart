import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/parqueadero.dart';
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
      return {'success': false, 'error': body['error'] ?? 'Error desconocido'};
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

  // HU 18 REGISTRAR PARQUEADERO
  Future<Map<String, dynamic>> registrarParqueadero(Parqueadero p) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/parqueaderos');
      final body = jsonEncode(p.toRegistroJson());
      print('DEBUG: Enviando POST a $url');
      print('DEBUG: Body enviado: $body');

      final response = await http
          .post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: body,
      )
          .timeout(const Duration(seconds: 10));

      print('DEBUG: Status code: ${response.statusCode}');
      print('DEBUG: Response body: "${response.body}"');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': _mensajeDeError(response)};
    } on TimeoutException {
      return {
        'success': false,
        'error': 'El servidor tardó demasiado en responder. Intenta de nuevo.',
      };
    } catch (e) {
      print('DEBUG: Excepción capturada: $e');
      return {
        'success': false,
        'error': 'No se pudo conectar con el servidor: $e',
      };
    }
  }

  /// Extrae un mensaje legible de una respuesta de error del backend.
  String _mensajeDeError(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        // Errores de @Valid en Quarkus: {"violations":[{"field":..,"message":..}]}
        final violations = decoded['violations'];
        if (violations is List && violations.isNotEmpty) {
          return violations
              .map((v) => v is Map ? v['message'] : v.toString())
              .where((m) => m != null)
              .join('\n');
        }
        final detalle =
            decoded['error'] ?? decoded['message'] ?? decoded['mensaje'];
        if (detalle != null) return detalle.toString();
      }
    } catch (_) {
      // cuerpo vacío o que no es JSON: se usa el mensaje por código
    }

    switch (response.statusCode) {
      case 400:
        return 'Hay datos inválidos en el formulario.';
      case 409:
        return 'Ya existe un parqueadero con esos datos.';
      default:
        return 'Error del servidor (${response.statusCode}).';
    }
  }
}
