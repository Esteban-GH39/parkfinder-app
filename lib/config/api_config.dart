class ApiConfig {
  //DIRECIÓN BASE BACKEND
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8860/kick',
  );

  //EndPoints de parqueadero (admin)
  static const String registrarParqueadero ='$baseUrl/parqueadero';
}
