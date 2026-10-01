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
  final double? tarifaNoche;
  final double? latitud;
  final double? longitud;
  //VARIABLES NUEVAS BASADA EN EL DTO
  final String? horaInicio;
  final String? horaFinal;

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
    this.tarifaNoche,
    this.latitud,
    this.longitud,
    //VARIABLES NUEVAS BASADA EN EL DTO
    this.horaInicio,
    this.horaFinal,
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
      tarifaNoche: (json['tarifaNoche'] as num?)?.toDouble(),
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      horaInicio: json['horaInicio'] as String? ?? '',
      horaFinal: json['horaFinal'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'zona': zona,
    'direccion': direccion,
    'nombrePropietario': representante,
    'capacidadTotal': capacidadTotal,
    'cuposOcupados': cuposOcupados,
    'tarifaHora': tarifaHora,
    'tarifaDia': tarifaDia,
    'tarifaNoche': tarifaNoche,
    'latitud': latitud,
    'longitud': longitud,
    //VARIABLES NUEVAS BASADA EN EL DTO
    'horaInicio': horaInicio,
    'horaFinal': horaFinal
  };

  // NUEVO: body exacto del ParqueaderoDto del backend
  Map<String, dynamic> toRegistroJson() => {
    'nombre': nombre.trim(),
    'direccion': direccion.trim(),
    'zona': zona.trim(),
    'capacidadTotal': capacidadTotal,
    'tarifaHora': tarifaHora,
    'tarifaDia': tarifaDia,
    'tarifaNoche': tarifaNoche,
    'horaInicio': _horaONull(horaInicio),
    'horaFinal': _horaONull(horaFinal),
    'nombrePropietario': representante.trim(),
  };

  static String? _horaONull(String? h) =>
      (h == null || h.trim().isEmpty) ? null : h.trim();
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
