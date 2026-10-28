import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:parkfinder_app/config/api_config.dart';
import '../models/comprobante.dart';

class ComprobanteService {

  //METODO PARA OBTENER UN COMPROBANTE DE PAGO POR ID
  Future<Comprobante> obtenerPorId(int idComprobante) async {
    final url = Uri.parse(ApiConfig.comprobantePorId(idComprobante));

    final http.Response response;
    try {
      response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw Exception('No se pudo conectar con el servidor: $e');
    }

    if (response.statusCode == 200) {
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      // Si la API no envía el id con una clave conocida, se usa el id consultado
      json['comprobanteId'] ??= idComprobante;
      return Comprobante.fromJson(json);
    } else if (response.statusCode == 404) {
      throw Exception('No existe un comprobante con id $idComprobante.');
    } else {
      throw Exception(
          'Error al obtener el comprobante. Código: ${response.statusCode}');
    }
  }
}
