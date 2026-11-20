import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/ruta_service.dart';
import '../../services/ubicacion_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets_comunes.dart';

/// Mapa con la mejor ruta en carro desde donde está el usuario hasta el parqueadero.
/// Si el parqueadero no tiene coordenadas se busca por su dirección. La navegación paso a paso se
/// delega a Google Maps (botón "Iniciar navegación").
class RutaScreen extends StatefulWidget {
  const RutaScreen({
    super.key,
    required this.nombre,
    required this.direccion,
    this.destino,
    RutaService? rutaService,
    UbicacionService? ubicacionService,
  }) : _rutaService = rutaService,
       _ubicacionService = ubicacionService;

  final String nombre;

  /// Se usa para ubicar el parqueadero cuando [destino] es null.
  final String direccion;
  final LatLng? destino;
  final RutaService? _rutaService;
  final UbicacionService? _ubicacionService;

  @override
  State<RutaScreen> createState() => _RutaScreenState();
}

class _RutaScreenState extends State<RutaScreen> {
  // Centro de Bogotá mientras no se sabe nada más.
  static const _bogota = LatLng(4.7110, -74.0721);

  late final RutaService _rutas = widget._rutaService ?? RutaService();
  late final UbicacionService _ubicacion =
      widget._ubicacionService ?? UbicacionService();
  final _mapa = MapController();

  bool _mapaListo = false;
  bool _cargando = true;
  String? _error;
  LatLng? _origen;
  LatLng? _destino;
  RutaCalculada? _ruta;

  @override
  void initState() {
    super.initState();
    _destino = widget.destino;
    _calcular();
  }

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  Future<void> _calcular() async {
    setState(() {
      _cargando = true;
      _error = null;
      _ruta = null;
    });

    // 1) Dónde está el parqueadero
    var destino = _destino;
    destino ??= await _rutas.geocodificar(
      '${widget.direccion}, Bogotá, Colombia',
    );
    if (!mounted) return;
    if (destino == null) {
      setState(() {
        _cargando = false;
        _error = 'No pudimos ubicar este parqueadero en el mapa.';
      });
      return;
    }
    setState(() => _destino = destino);
    _ajustarCamara();

    // 2) Dónde está el usuario
    LatLng origen;
    try {
      origen = await _ubicacion.actual();
    } on UbicacionException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.mensaje;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _origen = origen);

    // 3) La mejor ruta entre los dos
    final ruta = await _rutas.calcular(origen, destino);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _ruta = ruta;
      if (ruta == null) {
        _error = 'No se pudo calcular la ruta. Revisa tu conexión e intenta de nuevo.';
      }
    });
    _ajustarCamara();
  }

  /// Encuadra la ruta (o los dos puntos) en el mapa. Solo se puede cuando el mapa ya se dibujó.
  void _ajustarCamara() {
    if (!_mapaListo) return;
    final puntos = _ruta?.puntos ??
        [if (_origen != null) _origen!, if (_destino != null) _destino!];
    if (puntos.isEmpty) return;
    if (puntos.length == 1) {
      _mapa.move(puntos.first, 16);
      return;
    }
    _mapa.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(puntos),
        padding: const EdgeInsets.fromLTRB(40, 60, 40, 220),
      ),
    );
  }

  Future<void> _navegar() async {
    final destino = _destino;
    if (destino == null) return;
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${destino.latitude},${destino.longitude}',
      'travelmode': 'driving',
    });
    var abierto = false;
    try {
      abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      abierto = false;
    }
    if (!abierto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la navegación')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cómo llegar')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapa,
            options: MapOptions(
              initialCenter: _destino ?? _bogota,
              initialZoom: 14,
              onMapReady: () {
                _mapaListo = true;
                _ajustarCamara();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.parkfinder.parkfinder_app',
              ),
              if (_ruta != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _ruta!.puntos,
                      strokeWidth: 5,
                      color: AppColors.acento,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_origen != null)
                    Marker(
                      point: _origen!,
                      width: 26,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.acento,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  if (_destino != null)
                    Marker(
                      point: _destino!,
                      width: 46,
                      height: 52,
                      alignment: Alignment.topCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.oscuro,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.local_parking,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(child: _panel()),
          ),
        ],
      ),
    );
  }

  Widget _panel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Color(0x26000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            widget.direccion,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textoSuave, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          if (_cargando)
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Calculando la mejor ruta...'),
              ],
            )
          else if (_ruta != null) ...[
            Row(
              children: [
                const Icon(Icons.directions_car_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  _ruta!.duracionTexto,
                  key: const Key('rutaDuracion'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '· ${_ruta!.distanciaTexto}',
                  key: const Key('rutaDistancia'),
                  style: const TextStyle(color: AppColors.textoSuave),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Tiempo estimado sin contar el tráfico',
              style: TextStyle(color: AppColors.textoSuave, fontSize: 11.5),
            ),
          ] else if (_error != null)
            AvisoError(texto: _error!),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('botonRecalcularRuta'),
                  onPressed: _cargando ? null : _calcular,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Recalcular'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('botonIniciarNavegacion'),
                  onPressed: _destino == null ? null : _navegar,
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('Navegar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
