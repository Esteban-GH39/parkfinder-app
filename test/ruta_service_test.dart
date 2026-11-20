import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:parkfinder_app/services/ruta_service.dart';

void main() {
  const origen = LatLng(4.65, -74.06);
  const destino = LatLng(4.70, -74.04);

  http.Response json(Object cuerpo, [int estado = 200]) => http.Response(
    jsonEncode(cuerpo),
    estado,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  group('calcular', () {
    test('lee la línea, la distancia y el tiempo (GeoJSON viene como [lon, lat])', () async {
      late Uri pedida;
      final servicio = RutaService(
        cliente: MockClient((peticion) async {
          pedida = peticion.url;
          return json({
            'code': 'Ok',
            'routes': [
              {
                'distance': 12400.0,
                'duration': 1680.0,
                'geometry': {
                  'coordinates': [
                    [-74.06, 4.65],
                    [-74.05, 4.67],
                    [-74.04, 4.70],
                  ],
                },
              },
            ],
          });
        }),
      );

      final ruta = await servicio.calcular(origen, destino);

      expect(pedida.path, '/route/v1/driving/-74.06,4.65;-74.04,4.7');
      expect(pedida.queryParameters['geometries'], 'geojson');
      expect(ruta, isNotNull);
      expect(ruta!.puntos.first, const LatLng(4.65, -74.06));
      expect(ruta.puntos.last, const LatLng(4.70, -74.04));
      expect(ruta.distanciaTexto, '12,4 km');
      expect(ruta.duracionTexto, '28 min');
    });

    test('devuelve null si el servidor falla o no encuentra ruta', () async {
      final caido = RutaService(cliente: MockClient((_) async => json({}, 500)));
      expect(await caido.calcular(origen, destino), isNull);

      final sinRuta = RutaService(
        cliente: MockClient((_) async => json({'code': 'NoRoute', 'routes': []})),
      );
      expect(await sinRuta.calcular(origen, destino), isNull);
    });

    test('devuelve null si no hay conexión', () async {
      final servicio = RutaService(
        cliente: MockClient((_) async => throw http.ClientException('sin red')),
      );
      expect(await servicio.calcular(origen, destino), isNull);
    });
  });

  group('geocodificar', () {
    test('devuelve la primera coincidencia', () async {
      final servicio = RutaService(
        cliente: MockClient(
          (_) async => json([
            {'lat': '4.6097', 'lon': '-74.0817'},
          ]),
        ),
      );
      expect(await servicio.geocodificar('Calle 1, Bogotá'), const LatLng(4.6097, -74.0817));
    });

    test('devuelve null si no hay coincidencias', () async {
      final servicio = RutaService(cliente: MockClient((_) async => json([])));
      expect(await servicio.geocodificar('xyz'), isNull);
    });
  });

  group('textos', () {
    RutaCalculada con(double metros, double segundos) =>
        RutaCalculada(puntos: const [], distanciaMetros: metros, duracionSegundos: segundos);

    test('distancia', () {
      expect(con(850, 0).distanciaTexto, '850 m');
      expect(con(1000, 0).distanciaTexto, '1,0 km');
    });

    test('duración', () {
      expect(con(0, 10).duracionTexto, '1 min');
      expect(con(0, 7 * 60).duracionTexto, '7 min');
      expect(con(0, 65 * 60).duracionTexto, '1 h 05 min');
    });
  });
}
