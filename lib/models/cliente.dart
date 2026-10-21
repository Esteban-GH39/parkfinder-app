class Cliente {
  final String nombre;
  final String correo;
  final String contrasena;

  Cliente({
    required this.nombre,
    required this.correo,
    required this.contrasena,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'correo': correo,
    'contrasena': contrasena,
  };
}
