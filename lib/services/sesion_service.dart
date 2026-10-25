/// HU-02: sesión del usuario, en memoria. Se pierde al cerrar la app.
class SesionService {
  SesionService._();
  static final SesionService instancia = SesionService._();

  String? nombre;
  String? correo;
  String? rol;

  bool get activa => correo != null;
  bool get esAdmin => rol == 'ADMIN';

  void iniciar({
    required String nombre,
    required String correo,
    required String rol,
  }) {
    this.nombre = nombre;
    this.correo = correo;
    this.rol = rol;
  }

  void cerrar() {
    nombre = null;
    correo = null;
    rol = null;
  }
}
