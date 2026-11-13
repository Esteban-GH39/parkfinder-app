import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// HU-02: inicio de sesión del cliente
class AuthService {
  Future<Map<String, dynamic>> iniciarSesion(
    String correo,
    String contrasena,
  ) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return {'success': true, 'data': body};
      }
      if (response.statusCode == 401) {
        return {'success': false, 'error': 'Correo o contraseña incorrectos'};
      }
      return {
        'success': false,
        'error': 'No se pudo iniciar sesión (código ${response.statusCode})',
      };
    } catch (_) {
      return {'success': false, 'error': 'No se pudo conectar con el servidor'};
    }
  }
}
