import 'package:flutter/material.dart';

import '../../services/calificacion_service.dart';
import '../../services/sesion_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets_comunes.dart';

/// HU-13: calificar un parqueadero de 1 a 5 estrellas con un comentario opcional.
/// Al enviar con éxito se cierra devolviendo `true`.
class CalificarScreen extends StatefulWidget {
  const CalificarScreen({
    super.key,
    required this.parqueaderoId,
    required this.nombre,
    CalificacionService? servicio,
  }) : _servicio = servicio;

  final int parqueaderoId;
  final String nombre;
  final CalificacionService? _servicio;

  @override
  State<CalificarScreen> createState() => _CalificarScreenState();
}

class _CalificarScreenState extends State<CalificarScreen> {
  late final CalificacionService _servicio =
      widget._servicio ?? CalificacionService();
  final _comentarioCtrl = TextEditingController();

  int _estrellas = 0;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final clienteId = SesionService.instancia.id;
    if (clienteId == null) {
      setState(
        () => _error = 'No se pudo identificar tu cuenta. Inicia sesión de nuevo.',
      );
      return;
    }
    if (_estrellas == 0) {
      setState(() => _error = 'Elige de 1 a 5 estrellas');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    final resultado = await _servicio.calificar(
      clienteId: clienteId,
      parqueaderoId: widget.parqueaderoId,
      estrellas: _estrellas,
      comentario: _comentarioCtrl.text,
    );
    if (!mounted) return;
    if (resultado['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Gracias por tu calificación!')),
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = '${resultado['error']}';
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calificar parqueadero')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: TarjetaBlanca(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '¿Cómo fue tu experiencia?',
                  style: TextStyle(color: AppColors.textoSuave),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        key: Key('estrella_$i'),
                        iconSize: 40,
                        tooltip: '$i ${i == 1 ? 'estrella' : 'estrellas'}',
                        onPressed: _enviando
                            ? null
                            : () => setState(() => _estrellas = i),
                        icon: Icon(
                          i <= _estrellas ? Icons.star : Icons.star_border,
                          color: i <= _estrellas
                              ? Colors.amber
                              : AppColors.textoSuave,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('campoComentario'),
                  controller: _comentarioCtrl,
                  maxLength: 500,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Comentario (opcional)',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  AvisoError(texto: _error!),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('botonEnviarCalificacion'),
                    onPressed: _enviando ? null : _enviar,
                    child: _enviando
                        ? const CargandoEnBoton()
                        : const Text('Enviar calificación'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
