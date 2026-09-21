class Parqueadero {
  final int id;
  final String nombre;
  final String zona;
  final String direccion;
  final String representante;
  final int? capacidadTotal;
  final int? cuposOcupados;
  final double? tarifaHora;
  final double? tarifaDia;
  final double? latitud;
  final double? longitud;

  Parqueadero({
    required this.id,
    required this.nombre,
    required this.zona,
    required this.direccion,
    required this.representante,
    this.capacidadTotal,
    this.cuposOcupados,
    this.tarifaHora,
    this.tarifaDia,
    this.latitud,
    this.longitud,
  });

  factory Parqueadero.fromJson(Map<String, dynamic> json) {
    return Parqueadero(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      zona: json['zona'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      representante: json['representante'] as String? ?? '',
      capacidadTotal: (json['capacidadTotal'] as num?)?.toInt(),
      cuposOcupados: (json['cuposOcupados'] as num?)?.toInt(),
      tarifaHora: (json['tarifaHora'] as num?)?.toDouble(),
      tarifaDia: (json['tarifaDia'] as num?)?.toDouble(),
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'zona': zona,
    'direccion': direccion,
    'representante': representante,
    'capacidadTotal': capacidadTotal,
    'cuposOcupados': cuposOcupados,
    'tarifaHora': tarifaHora,
    'tarifaDia': tarifaDia,
    'latitud': latitud,
    'longitud': longitud,
  };
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
