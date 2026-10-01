import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:parkfinder_app/config/api_config.dart';
import '../models/parqueadero.dart'; // Ajusta la ruta a tu DTO/Modelo

class ParqueaderoService {

  Future<bool> registrarParqueadero( Parqueadero parqueadero) async {
    final url = Uri.parse(ApiConfig.registrarParqueadero);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(parqueadero.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true; // Petición exitosa
      } else {
        print('Error del servidor (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de conexión: $e');
      return false;
    }
  }
}