class Comprobante {
  final int id;
  final String? fechaGenerado;
  final double? valorPago;
  final String? medioPago;
  final String? estadoTransaccion;
  final int? fkComprobanteCliente;
  final int? fkComprobanteParqueadero;

  Comprobante({
    required this.id,
    this.fechaGenerado,
    this.valorPago,
    this.medioPago,
    this.estadoTransaccion,
    this.fkComprobanteCliente,
    this.fkComprobanteParqueadero,
  });

  factory Comprobante.fromJson(Map<String, dynamic> json) {
    return Comprobante(
      id: (json['comprobanteId'] as num?)?.toInt() ??
          (json['idComprobante'] as num?)?.toInt() ??
          (json['id_comprobante'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          0,
      fechaGenerado: json['fechaGenerado']?.toString(),
      valorPago: (json['valorPago'] as num?)?.toDouble(),
      medioPago: json['medioPago'] as String?,
      estadoTransaccion: json['estadoTransaccion'] as String?,
      fkComprobanteCliente: (json['fk_comprobante_cliente'] as num?)?.toInt(),
      fkComprobanteParqueadero:
          (json['fk_comprobante_parqueadero'] as num?)?.toInt(),
    );
  }
}
