/// HU-02: sesión del usuario, en memoria. Se pierde al cerrar la app.
class SesionService {
  SesionService._();
  static final SesionService instancia = SesionService._();

  int? id;
  String? nombre;
  String? correo;
  String? rol;

  /// Dueño al que pertenece la cuenta cuando el rol es ADMIN.
  int? adminId;

  bool get activa => correo != null;
  bool get esAdmin => rol == 'ADMIN';

  void iniciar({
    int? id,
    required String nombre,
    required String correo,
    required String rol,
    int? adminId,
  }) {
    this.id = id;
    this.nombre = nombre;
    this.correo = correo;
    this.rol = rol;
    this.adminId = adminId;
  }

  void cerrar() {
    id = null;
    nombre = null;
    correo = null;
    rol = null;
    adminId = null;
  }
}
