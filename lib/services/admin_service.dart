import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Vista del dueño: sus parqueaderos y las reservas que reciben.
class AdminService {
  /// Parqueaderos del dueño, con sus cupos disponibles.
  Future<List<dynamic>> misParqueaderos(int adminId) =>
      _lista('/parqueaderos/admin/$adminId');

  /// Reservas de esos parqueaderos, la más reciente primero.
  Future<List<dynamic>> misReservas(int adminId) =>
      _lista('/reservas/admin/$adminId');

  Future<List<dynamic>> _lista(String ruta) async {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}$ruta'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('El servidor respondió ${response.statusCode}');
    }
    if (response.body.isEmpty) return [];
    return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
  }
}
