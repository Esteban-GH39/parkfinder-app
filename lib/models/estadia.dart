/// Tipo de vehículo, igual que el enum TipoVehiculo del backend.
enum TipoVehiculo {
  carro('CARRO', 'Carro'),
  moto('MOTO', 'Moto');

  const TipoVehiculo(this.api, this.etiqueta);

  /// Valor que espera el backend.
  final String api;
  final String etiqueta;

  static TipoVehiculo desdeApi(String? valor) =>
      valor?.toUpperCase() == 'MOTO' ? TipoVehiculo.moto : TipoVehiculo.carro;
}

/// Un vehículo registrado al ingresar al parqueadero.
class Estadia {
  final int id;
  final int parqueaderoId;
  final int? reservaId;
  final String placa;
  final TipoVehiculo tipoVehiculo;
  final DateTime? ingresoEn;

  Estadia({
    required this.id,
    required this.parqueaderoId,
    this.reservaId,
    required this.placa,
    required this.tipoVehiculo,
    this.ingresoEn,
  });

  factory Estadia.fromJson(Map<String, dynamic> json) => Estadia(
    id: (json['id'] as num?)?.toInt() ?? 0,
    parqueaderoId: (json['parqueaderoId'] as num?)?.toInt() ?? 0,
    reservaId: (json['reservaId'] as num?)?.toInt(),
    placa: json['placa'] as String? ?? '',
    tipoVehiculo: TipoVehiculo.desdeApi(json['tipoVehiculo'] as String?),
    ingresoEn: _fecha(json['ingresoEn']),
  );
}

/// Lo que debe pagar un vehículo por el tiempo que lleva (o llevó) en el parqueadero.
class Liquidacion {
  final int estadiaId;
  final String placa;
  final TipoVehiculo tipoVehiculo;
  final int? reservaId;
  final DateTime? ingresoEn;

  /// Hora de salida si [cerrada]; si no, la hora de la consulta.
  final DateTime? salidaEn;
  final bool cerrada;
  final int minutos;
  final int diasCompletos;
  final int minutosDiurnos;
  final int minutosNocturnos;
  final double? tarifaHora;
  final double? tarifaDia;
  final double? tarifaNoche;
  final double valorMinuto;
  final double valorTotal;
  final bool aplicoTarifaDia;
  final bool aplicoTarifaNoche;

  Liquidacion({
    required this.estadiaId,
    required this.placa,
    required this.tipoVehiculo,
    this.reservaId,
    this.ingresoEn,
    this.salidaEn,
    this.cerrada = false,
    this.minutos = 0,
    this.diasCompletos = 0,
    this.minutosDiurnos = 0,
    this.minutosNocturnos = 0,
    this.tarifaHora,
    this.tarifaDia,
    this.tarifaNoche,
    this.valorMinuto = 0,
    this.valorTotal = 0,
    this.aplicoTarifaDia = false,
    this.aplicoTarifaNoche = false,
  });

  factory Liquidacion.fromJson(Map<String, dynamic> json) => Liquidacion(
    estadiaId: (json['estadiaId'] as num?)?.toInt() ?? 0,
    placa: json['placa'] as String? ?? '',
    tipoVehiculo: TipoVehiculo.desdeApi(json['tipoVehiculo'] as String?),
    reservaId: (json['reservaId'] as num?)?.toInt(),
    ingresoEn: _fecha(json['ingresoEn']),
    salidaEn: _fecha(json['salidaEn']),
    cerrada: json['cerrada'] == true,
    minutos: (json['minutos'] as num?)?.toInt() ?? 0,
    diasCompletos: (json['diasCompletos'] as num?)?.toInt() ?? 0,
    minutosDiurnos: (json['minutosDiurnos'] as num?)?.toInt() ?? 0,
    minutosNocturnos: (json['minutosNocturnos'] as num?)?.toInt() ?? 0,
    tarifaHora: (json['tarifaHora'] as num?)?.toDouble(),
    tarifaDia: (json['tarifaDia'] as num?)?.toDouble(),
    tarifaNoche: (json['tarifaNoche'] as num?)?.toDouble(),
    valorMinuto: (json['valorMinuto'] as num?)?.toDouble() ?? 0,
    valorTotal: (json['valorTotal'] as num?)?.toDouble() ?? 0,
    aplicoTarifaDia: json['aplicoTarifaDia'] == true,
    aplicoTarifaNoche: json['aplicoTarifaNoche'] == true,
  );

  /// Tiempo transcurrido legible: "2 d 3 h 15 min", "45 min".
  String get tiempoTexto => formatearMinutos(minutos);
}

/// "2 d 3 h 15 min", "1 h 5 min", "45 min".
String formatearMinutos(int minutos) {
  final dias = minutos ~/ 1440;
  final horas = (minutos % 1440) ~/ 60;
  final mins = minutos % 60;
  final partes = <String>[
    if (dias > 0) '$dias d',
    if (horas > 0) '$horas h',
    if (mins > 0 || (dias == 0 && horas == 0)) '$mins min',
  ];
  return partes.join(' ');
}

/// Pesos sin decimales y con punto de miles: 12500 -> "$12.500".
String formatearPesos(double valor) {
  final entero = valor.round().toString();
  final conPuntos = entero.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '\$$conPuntos';
}

/// "15/11/2026 18:05"
String formatearFechaHora(DateTime? fecha) {
  if (fecha == null) return '-';
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} '
      '${dos(fecha.hour)}:${dos(fecha.minute)}';
}

DateTime? _fecha(dynamic valor) =>
    valor == null ? null : DateTime.tryParse(valor.toString());
