import 'package:flutter/material.dart';

import '../../services/calificacion_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets_comunes.dart';

/// HU-13: el dueño lee el promedio y los comentarios que los clientes dejaron en un parqueadero.
/// Es solo de lectura.
class CalificacionesParqueaderoScreen extends StatefulWidget {
  const CalificacionesParqueaderoScreen({
    super.key,
    required this.parqueaderoId,
    required this.nombre,
    CalificacionService? servicio,
  }) : _servicio = servicio;

  final int parqueaderoId;
  final String nombre;
  final CalificacionService? _servicio;

  @override
  State<CalificacionesParqueaderoScreen> createState() =>
      _CalificacionesParqueaderoScreenState();
}

class _CalificacionesParqueaderoScreenState
    extends State<CalificacionesParqueaderoScreen> {
  late final CalificacionService _servicio =
      widget._servicio ?? CalificacionService();

  Map<String, dynamic>? _resumen;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resumen = await _servicio.resumen(widget.parqueaderoId);
      if (!mounted) return;
      setState(() {
        _resumen = resumen;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron consultar las opiniones. Intenta de nuevo.';
        _cargando = false;
      });
    }
  }

  String _fecha(dynamic iso) {
    final d = DateTime.tryParse('${iso ?? ''}');
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _estrellas(int n) => '★' * n + '☆' * (5 - n);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Opiniones · ${widget.nombre}')),
    body: SafeArea(child: _contenido()),
  );

  Widget _contenido() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvisoError(texto: _error!),
              const SizedBox(height: 12),
              FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    final r = _resumen!;
    final total = ((r['total'] as num?) ?? 0).toInt();
    final promedio = (r['promedio'] as num?)?.toDouble();
    final lista = ((r['calificaciones'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();

    if (total == 0 || promedio == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aún no hay opiniones de tus clientes',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textoSuave),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TarjetaBlanca(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  promedio.toStringAsFixed(1),
                  key: const Key('promedioAdmin'),
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '$total ${total == 1 ? 'opinión' : 'opiniones'}',
                    style: const TextStyle(color: AppColors.textoSuave),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final c in lista) ...[
            TarjetaBlanca(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${c['clienteNombre'] ?? 'Cliente'}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        _fecha(c['creadaEn']),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textoSuave,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _estrellas(((c['estrellas'] as num?) ?? 0).toInt()),
                    style: const TextStyle(color: AppColors.acento),
                  ),
                  if ((c['comentario'] ?? '').toString().trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('${c['comentario']}'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
