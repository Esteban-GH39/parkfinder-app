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
      return Comprobante.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      throw Exception('No existe un comprobante con id $idComprobante.');
    } else {
      throw Exception(
          'Error al obtener el comprobante. Código: ${response.statusCode}');
    }
  }
}
