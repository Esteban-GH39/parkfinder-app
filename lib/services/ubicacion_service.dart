import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// No se pudo saber dónde está el usuario; [mensaje] se muestra tal cual.
class UbicacionException implements Exception {
  UbicacionException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Ubicación actual del teléfono (GPS), pidiendo el permiso si hace falta.
class UbicacionService {
  Future<LatLng> actual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw UbicacionException(
        'Activa la ubicación (GPS) del teléfono para calcular la ruta.',
      );
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied) {
      throw UbicacionException('Necesitamos el permiso de ubicación para calcular la ruta.');
    }
    if (permiso == LocationPermission.deniedForever) {
      throw UbicacionException(
        'El permiso de ubicación está bloqueado. Actívalo en los ajustes de la app.',
      );
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      throw UbicacionException('No se pudo obtener tu ubicación. Intenta de nuevo.');
    }
  }
}
