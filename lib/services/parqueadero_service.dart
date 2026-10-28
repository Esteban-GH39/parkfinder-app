import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:parkfinder_app/config/api_config.dart';
import '../models/parqueadero.dart'; // Ajusta la ruta a tu DTO/Modelo

class ParqueaderoService {

  //METODO PARA REGISGRA PARQUEADERO
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

  //METODO PARA GESTIONAR CUPOS DISPONIBLES DEL PARQUEADERO
  Future<bool> actualizarCuposDisponibles({
    required int idParqueadero,
    required int idAdmin,
    required int nuevosCupos,
  }) async {
    final url = Uri.parse(ApiConfig.actualizarCuposParqueadero(idParqueadero));

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': idAdmin,
        'cuposDisponibles': nuevosCupos,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {

      final errorMsg = response.body.isNotEmpty
          ? response.body
          : 'Error al actualizar cupos (${response.statusCode})';
      throw Exception(errorMsg);
    }
  }
}