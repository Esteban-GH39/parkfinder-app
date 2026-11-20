import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'errores_api.dart';

/// Perfil de la cuenta (cliente o administrador). Todos devuelven `{success, data}` o `{success, error}`.
class PerfilService {
  /// Nombre, correo, rol y, si es administrador, teléfono y cédula.
  Future<Map<String, dynamic>> obtener(int id) => llamar(
    () => http.get(Uri.parse('${ApiConfig.baseUrl}/clientes/$id')),
    porDefecto: 'No se pudo cargar tu perfil',
  );

  /// Cambia el nombre y, solo para administradores, el teléfono.
  Future<Map<String, dynamic>> actualizar(
    int id, {
    required String nombre,
    int? telefono,
  }) => llamar(
    () => http.put(
      Uri.parse('${ApiConfig.baseUrl}/clientes/$id'),
      headers: cabecerasJson,
      body: jsonEncode({'nombre': nombre, if (telefono != null) 'telefono': telefono}),
    ),
    porDefecto: 'No se pudo guardar tu perfil',
  );

  Future<Map<String, dynamic>> cambiarContrasena(
    int id, {
    required String actual,
    required String nueva,
  }) => llamar(
    () => http.put(
      Uri.parse('${ApiConfig.baseUrl}/clientes/$id/contrasena'),
      headers: cabecerasJson,
      body: jsonEncode({'contrasenaActual': actual, 'contrasenaNueva': nueva}),
    ),
    exito: const {204},
    porDefecto: 'No se pudo cambiar la contraseña',
  );
}
