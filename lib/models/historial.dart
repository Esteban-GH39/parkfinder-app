// HU-24: historial de reservas e ingresos de los parqueaderos del dueño.

/// Periodo por el que se filtra el historial.
enum PeriodoHistorial {
  dia('DIA', 'Día'),
  semana('SEMANA', 'Semana'),
  mes('MES', 'Mes');

  const PeriodoHistorial(this.api, this.etiqueta);
  final String api;
  final String etiqueta;

  /// Una fecha dentro del periodo anterior (-1) o siguiente (+1).
  DateTime mover(DateTime fecha, int pasos) => switch (this) {
    PeriodoHistorial.dia => DateTime(
      fecha.year,
      fecha.month,
      fecha.day + pasos,
    ),
    PeriodoHistorial.semana => DateTime(
      fecha.year,
      fecha.month,
      fecha.day + 7 * pasos,
    ),
    // Día 1 para que "31 de enero + 1 mes" no salte a marzo
    PeriodoHistorial.mes => DateTime(fecha.year, fecha.month + pasos, 1),
  };
}

double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;
DateTime? _fecha(dynamic v) => v == null ? null : DateTime.parse('$v');

class Historial {
  Historial({
    required this.desde,
    required this.hasta,
    required this.ingresosReservas,
    required this.ingresosEstadias,
    required this.ingresosTotales,
    required this.totalReservas,
    required this.reservasPagadas,
    required this.vehiculosCobrados,
    required this.desglose,
    required this.reservas,
    required this.cobros,
  });

  final DateTime desde;
  final DateTime hasta;
  final double ingresosReservas;
  final double ingresosEstadias;
  final double ingresosTotales;
  final int totalReservas;
  final int reservasPagadas;
  final int vehiculosCobrados;
  final List<IngresoDia> desglose;
  final List<ReservaHistorial> reservas;
  final List<CobroEstadia> cobros;

  factory Historial.fromJson(Map<String, dynamic> j) => Historial(
    desde: DateTime.parse('${j['desde']}'),
    hasta: DateTime.parse('${j['hasta']}'),
    ingresosReservas: _num(j['ingresosReservas']),
    ingresosEstadias: _num(j['ingresosEstadias']),
    ingresosTotales: _num(j['ingresosTotales']),
    totalReservas: (j['totalReservas'] as num?)?.toInt() ?? 0,
    reservasPagadas: (j['reservasPagadas'] as num?)?.toInt() ?? 0,
    vehiculosCobrados: (j['vehiculosCobrados'] as num?)?.toInt() ?? 0,
    desglose: [
      for (final d in (j['desglose'] as List? ?? []))
        IngresoDia.fromJson(d as Map<String, dynamic>),
    ],
    reservas: [
      for (final r in (j['reservas'] as List? ?? []))
        ReservaHistorial.fromJson(r as Map<String, dynamic>),
    ],
    cobros: [
      for (final c in (j['cobros'] as List? ?? []))
        CobroEstadia.fromJson(c as Map<String, dynamic>),
    ],
  );
}

class IngresoDia {
  IngresoDia({
    required this.fecha,
    required this.reservas,
    required this.estadias,
    required this.total,
  });

  final DateTime fecha;
  final double reservas;
  final double estadias;
  final double total;

  factory IngresoDia.fromJson(Map<String, dynamic> j) => IngresoDia(
    fecha: DateTime.parse('${j['fecha']}'),
    reservas: _num(j['reservas']),
    estadias: _num(j['estadias']),
    total: _num(j['total']),
  );
}

class ReservaHistorial {
  ReservaHistorial({
    required this.id,
    required this.parqueaderoNombre,
    required this.clienteNombre,
    required this.cantidad,
    required this.cantidadMotos,
    required this.codigoReserva,
    required this.estado,
    required this.creadaEn,
    required this.fechaHoraLlegada,
    required this.validadaEn,
    required this.montoPagado,
  });

  final int id;
  final String? parqueaderoNombre;
  final String? clienteNombre;
  final int cantidad;
  final int cantidadMotos;
  final int? codigoReserva;
  final String estado;
  final DateTime? creadaEn;
  final DateTime? fechaHoraLlegada;
  final DateTime? validadaEn;
  final double montoPagado;

  factory ReservaHistorial.fromJson(Map<String, dynamic> j) => ReservaHistorial(
    id: (j['id'] as num).toInt(),
    parqueaderoNombre: j['parqueaderoNombre'] as String?,
    clienteNombre: j['clienteNombre'] as String?,
    cantidad: (j['cantidad'] as num?)?.toInt() ?? 1,
    cantidadMotos: (j['cantidadMotos'] as num?)?.toInt() ?? 0,
    codigoReserva: (j['codigoReserva'] as num?)?.toInt(),
    estado: '${j['estado'] ?? ''}',
    creadaEn: _fecha(j['creadaEn']),
    fechaHoraLlegada: _fecha(j['fechaHoraLlegada']),
    validadaEn: _fecha(j['validadaEn']),
    montoPagado: _num(j['montoPagado']),
  );
}

class CobroEstadia {
  CobroEstadia({
    required this.id,
    required this.parqueaderoNombre,
    required this.reservaId,
    required this.placa,
    required this.tipoVehiculo,
    required this.ingresoEn,
    required this.salidaEn,
    required this.minutos,
    required this.valorCobrado,
  });

  final int id;
  final String? parqueaderoNombre;
  final int? reservaId;
  final String placa;
  final String tipoVehiculo;
  final DateTime? ingresoEn;
  final DateTime? salidaEn;
  final int minutos;
  final double valorCobrado;

  factory CobroEstadia.fromJson(Map<String, dynamic> j) => CobroEstadia(
    id: (j['id'] as num).toInt(),
    parqueaderoNombre: j['parqueaderoNombre'] as String?,
    reservaId: (j['reservaId'] as num?)?.toInt(),
    placa: '${j['placa'] ?? ''}',
    tipoVehiculo: '${j['tipoVehiculo'] ?? 'CARRO'}',
    ingresoEn: _fecha(j['ingresoEn']),
    salidaEn: _fecha(j['salidaEn']),
    minutos: (j['minutos'] as num?)?.toInt() ?? 0,
    valorCobrado: _num(j['valorCobrado']),
  );
}
