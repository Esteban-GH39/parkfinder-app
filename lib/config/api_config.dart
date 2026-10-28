class ApiConfig {
  //DIRECIÓN BASE BACKEND
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8860/kick',
  );

  //EndPoints de parqueadero (admin)
  static const String registrarParqueadero ='$baseUrl/parqueadero';

  //LISTAR PARQUEADERO POR ID ADMIN
  static  String listarParqueaderosAdmin(int idAdmin) => '$baseUrl/parqueaderos/admin/$idAdmin';

  //ACTUALIZAR CUPO PARQUEADERO
  static String actualizarCuposParqueadero(int idParqueadero) => '$baseUrl/parqueaderos/$idParqueadero/cuposDisponibles';
}
