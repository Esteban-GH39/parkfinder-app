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


  //METODO LISTAR PARQUEADERO
  Future<List<Parqueadero>> listarPorAdmin(int idAdmin) async {
    final url = Uri.parse(ApiConfig.listarParqueaderosAdmin(idAdmin));

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Parqueadero.fromJson(json)).toList();
      } else {
        throw Exception(
            'Error al obtener parqueaderos. Código: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('No se pudo conectar con el servidor: $e');
    }
  }
}