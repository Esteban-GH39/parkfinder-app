import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'errores_api.dart';

/// Billetera del cliente: saldo en pesos, movimientos y recargas con la pasarela simulada.
class BilleteraService {
  /// Saldo actual, o null si no se pudo consultar (no debe estorbar la pantalla que lo muestra).
  Future<int?> saldo(int clienteId) async {
    final r = await llamar(
      () => http.get(Uri.parse('${ApiConfig.baseUrl}/billetera/$clienteId')),
    );
    if (r['success'] != true || r['data'] is! Map) return null;
    return ((r['data'] as Map)['saldo'] as num?)?.toInt();
  }

  /// Recargas, pagos y reembolsos, el más reciente primero. Vacío si falla la consulta.
  Future<List<Map<String, dynamic>>> movimientos(int clienteId) async {
    final r = await llamar(
      () => http.get(Uri.parse('${ApiConfig.baseUrl}/billetera/$clienteId/movimientos?limite=30')),
    );
    if (r['success'] != true || r['data'] is! List) return [];
    return (r['data'] as List).cast<Map<String, dynamic>>();
  }

  /// [medio] es TARJETA, PSE o NEQUI. Devuelve `{success, data}` (data.estado es APROBADO o
  /// RECHAZADO, data.saldo el saldo resultante) o `{success: false, error}`.
  Future<Map<String, dynamic>> recargar({
    required int clienteId,
    required int monto,
    required String medio,
    required Map<String, String> datos,
  }) => llamar(
    () => http.post(
      Uri.parse('${ApiConfig.baseUrl}/billetera/$clienteId/recargas'),
      headers: cabecerasJson,
      body: jsonEncode({'monto': monto, 'medioPago': medio, 'datos': datos}),
    ),
    exito: const {201},
    porDefecto: 'No se pudo procesar la recarga',
  );
}
