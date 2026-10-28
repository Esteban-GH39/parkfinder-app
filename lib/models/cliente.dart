class Cliente {
  final String nombre;
  final String correo;
  final String contrasena;

  /// CLIENTE o ADMIN (dueño de parqueadero).
  final String rol;
  final int? telefono;
  final int? cedula;

  Cliente({
    required this.nombre,
    required this.correo,
    required this.contrasena,
    this.rol = 'CLIENTE',
    this.telefono,
    this.cedula,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'correo': correo,
    'contrasena': contrasena,
    'rol': rol,
    if (telefono != null) 'telefono': telefono,
    if (cedula != null) 'cedula': cedula,
  };
}
