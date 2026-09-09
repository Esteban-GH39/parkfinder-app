import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../common/api_client.dart';

/// Usuario tal como lo devuelve el backend (HU-01).
class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  final int id;
  final String nombre;
  final String email;
  final String rol;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: json['rol'] as String,
    );
  }
}

/// El correo ya tiene una cuenta (respuesta 409 del backend).
class EmailYaRegistradoException implements Exception {
  const EmailYaRegistradoException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Falló la validación de los datos enviados (respuesta 400 del backend).
class ValidacionException implements Exception {
  const ValidacionException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Llamadas al módulo `users` del backend.
class UsuarioApi {
  UsuarioApi({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// HU-01: registro de cuenta de cliente.
  ///
  /// Devuelve el usuario creado (201). Lanza [EmailYaRegistradoException] si el
  /// correo ya existe (409) o [ValidacionException] si los datos no pasan las
  /// validaciones del backend (400).
  Future<Usuario> registrarCliente({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final respuesta = await _client.post(
      Uri.parse('$baseUrl/usuarios/clientes'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'password': password,
      }),
    );

    switch (respuesta.statusCode) {
      case 201:
        return Usuario.fromJson(
          jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>,
        );
      case 409:
        throw EmailYaRegistradoException(
          _mensajeDeConflicto(respuesta.bodyBytes),
        );
      case 400:
        throw ValidacionException(_mensajeDeValidacion(respuesta.bodyBytes));
      default:
        throw Exception(
          'Error inesperado del servidor (${respuesta.statusCode})',
        );
    }
  }

  /// El backend responde `{"mensaje": "..."}` en el 409.
  String _mensajeDeConflicto(List<int> cuerpo) {
    try {
      final json = jsonDecode(utf8.decode(cuerpo)) as Map<String, dynamic>;
      final mensaje = json['mensaje'];
      if (mensaje is String && mensaje.isNotEmpty) {
        return mensaje;
      }
    } catch (_) {
      // Cuerpo inesperado: se usa el mensaje por defecto de abajo.
    }
    return 'Ya existe una cuenta registrada con este correo';
  }

  /// Quarkus devuelve las violaciones de validación en `violations[]`.
  String _mensajeDeValidacion(List<int> cuerpo) {
    try {
      final json = jsonDecode(utf8.decode(cuerpo));
      if (json is Map<String, dynamic>) {
        final violaciones = json['violations'];
        if (violaciones is List && violaciones.isNotEmpty) {
          final mensajes = violaciones
              .whereType<Map<String, dynamic>>()
              .map((v) => v['message'])
              .whereType<String>()
              .toList();
          if (mensajes.isNotEmpty) {
            return mensajes.join('\n');
          }
        }
      }
    } catch (_) {
      // Cuerpo inesperado: se usa el mensaje por defecto de abajo.
    }
    return 'Revisa los datos ingresados';
  }

  void dispose() => _client.close();
}
