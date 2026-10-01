class Parqueadero {
  final int id;
  final String nombre;
  final String direccion;
  final String zona;
  final String nombrePropietario;
  final int? capacidadTotal;
  final double? tarifaHora;
  final double? tarifaDia;
  final double? tarifaNoche;
  final String? horaInicio;
  final String? horaFin;

  Parqueadero({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.zona,
    required this.nombrePropietario,
    this.capacidadTotal,
    this.tarifaHora,
    this.tarifaDia,
    this.tarifaNoche,
    this.horaInicio,
    this.horaFin,
  });

  factory Parqueadero.fromJson(Map<String, dynamic> json) {
    return Parqueadero(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      zona: json['zona'] as String? ?? '',
      nombrePropietario: json['nombrePropietario'] as String? ?? '',
      capacidadTotal: (json['capacidadTotal'] as num?)?.toInt(),
      tarifaHora: (json['tarifaHora'] as num?)?.toDouble(),
      tarifaDia: (json['tarifaDia'] as num?)?.toDouble(),
      tarifaNoche: (json['tarifaNoche'] as num?)?.toDouble(),
      horaInicio: json['horaInicio'] as String?,
      horaFin: json['horaFin'] as String?,
    );
  }
}

/// Un renglón del historial de trazabilidad de HU-19.
class CambioParqueadero {
  final String campo;
  final String? valorAnterior;
  final String? valorNuevo;
  final String? fecha;

  CambioParqueadero({
    required this.campo,
    this.valorAnterior,
    this.valorNuevo,
    this.fecha,
  });

  factory CambioParqueadero.fromJson(Map<String, dynamic> json) {
    return CambioParqueadero(
      campo: json['campo'] as String? ?? '',
      valorAnterior: json['valorAnterior'] as String?,
      valorNuevo: json['valorNuevo'] as String?,
      fecha: json['fecha'] as String?,
    );
  }
}
