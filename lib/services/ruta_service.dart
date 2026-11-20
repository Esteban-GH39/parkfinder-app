import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Ruta en carro entre dos puntos: la línea para dibujar, la distancia y el tiempo estimado.
class RutaCalculada {
  const RutaCalculada({
    required this.puntos,
    required this.distanciaMetros,
    required this.duracionSegundos,
  });

  final List<LatLng> puntos;
  final double distanciaMetros;
  final double duracionSegundos;

  /// 850 m · 12,4 km
  String get distanciaTexto {
    if (distanciaMetros < 1000) return '${distanciaMetros.round()} m';
    return '${(distanciaMetros / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  /// 7 min · 1 h 05 min
  String get duracionTexto {
    final minutos = (duracionSegundos / 60).round();
    if (minutos < 1) return '1 min';
    if (minutos < 60) return '$minutos min';
    final h = minutos ~/ 60;
    final m = (minutos % 60).toString().padLeft(2, '0');
    return '$h h $m min';
  }
}

/// Ruta con OSRM y geocodificación con Nominatim (OpenStreetMap). No piden llave de API, pero son
/// servidores públicos de demostración: sirven para desarrollo y pocas consultas. Para producción hay
/// que montar OSRM propio o cambiar [urlOsrm] por un proveedor de pago (Mapbox, OpenRouteService...).
class RutaService {
  RutaService({http.Client? cliente, this.urlOsrm = 'https://router.project-osrm.org'})
    : _cliente = cliente ?? http.Client();

  final http.Client _cliente;
  final String urlOsrm;

  static const _agente = 'ParkFinder/1.0 (com.parkfinder.parkfinder_app)';

  /// La mejor ruta en carro (la más rápida, sin contar el tráfico), o null si no se pudo calcular.
  Future<RutaCalculada?> calcular(LatLng origen, LatLng destino) async {
    final coordenadas =
        '${origen.longitude},${origen.latitude};${destino.longitude},${destino.latitude}';
    final uri = Uri.parse(
      '$urlOsrm/route/v1/driving/$coordenadas',
    ).replace(queryParameters: {'overview': 'full', 'geometries': 'geojson'});
    try {
      final r = await _cliente
          .get(uri, headers: {'User-Agent': _agente})
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (body is! Map || body['code'] != 'Ok') return null;
      final rutas = body['routes'];
      if (rutas is! List || rutas.isEmpty) return null;
      final ruta = rutas.first as Map;
      final geometria = (ruta['geometry'] as Map)['coordinates'] as List;
      // GeoJSON viene como [longitud, latitud]
      final puntos = [
        for (final c in geometria)
          LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
      ];
      if (puntos.length < 2) return null;
      return RutaCalculada(
        puntos: puntos,
        distanciaMetros: (ruta['distance'] as num).toDouble(),
        duracionSegundos: (ruta['duration'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Busca una dirección en Colombia. Sirve para los parqueaderos que se registraron sin coordenadas.
  Future<LatLng?> geocodificar(String direccion) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': direccion,
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'co',
    });
    try {
      final r = await _cliente
          .get(uri, headers: {'User-Agent': _agente})
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (body is! List || body.isEmpty) return null;
      final lugar = body.first as Map;
      return LatLng(
        double.parse('${lugar['lat']}'),
        double.parse('${lugar['lon']}'),
      );
    } catch (_) {
      return null;
    }
  }
}
