import 'package:flutter/foundation.dart';

/// Configuración de acceso al backend (parkfinder-api / Quarkus).
class ApiConfig {
  const ApiConfig._();

  /// URL base del backend en desarrollo.
  ///
  /// El emulador de Android no ve `localhost` de la máquina anfitriona: para
  /// llegar a ella usa la IP especial `10.0.2.2`. En web y escritorio sí se
  /// usa `localhost` directamente.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
}
