import 'package:flutter/material.dart';
import '../../models/parqueadero.dart';
import '../../services/parqueadero_service.dart';

class GestionCuposParqueaderoScreen extends StatefulWidget {
  final Parqueadero parqueadero;

  const GestionCuposParqueaderoScreen({
    super.key,
    required this.parqueadero,
  });

  @override
  State<GestionCuposParqueaderoScreen> createState() =>
      _DetalleParqueaderoScreenState();
}

class _DetalleParqueaderoScreenState extends State<GestionCuposParqueaderoScreen> {
  final ParqueaderoService _parqueaderoService = ParqueaderoService();

  late int _cuposDisponibles;
  late int _capacidadTotal;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _capacidadTotal = widget.parqueadero.capacidadTotal ?? 0;
    _cuposDisponibles = widget.parqueadero.cuposDisponibles;
  }

  // METODO PARA MODIFICAR ACTUALIZAR CUPOS DISNPONIBLES CON LA API
  Future<void> _modificarCupos(int delta) async {
    final nuevoValor = _cuposDisponibles + delta;

    // Validación preventiva en Flutter
    if (nuevoValor < 0) {
      _mostrarSnackBar('No hay cupos disponibles para descontar.', isError: true);
      return;
    }
    if (nuevoValor > _capacidadTotal) {
      _mostrarSnackBar(
        'La cantidad de cupos no puede superar la capacidad total ($_capacidadTotal).',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _parqueaderoService.actualizarCuposDisponibles(
        idParqueadero: widget.parqueadero.id,
        idAdmin: widget.parqueadero.fk_parqueadero_admin, // 👈 Enviado al body JSON
        nuevosCupos: nuevoValor,
      );

      setState(() {
        _cuposDisponibles = nuevoValor;
      });

      _mostrarSnackBar('Cupos actualizados correctamente.');
    } catch (e) {
      // Muestra la excepción lanzada desde Quarkus en el SnackBar
      _mostrarSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarSnackBar(String mensaje, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Pantalla de 1 Parqueadero',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Nombre del parqueadero
              Text(
                widget.parqueadero.nombre.isNotEmpty
                    ? widget.parqueadero.nombre
                    : 'Parqueadero ${widget.parqueadero.id}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Capacidad Total
              Text(
                'Capacidad: $_capacidadTotal',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              // Cupos Disponibles
              Text(
                'Cupos Disponibles: $_cuposDisponibles',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 40),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),

              Expanded(
                child: ListView(
                  children: [
                    // 1. Botón Código Reserva (Sin funcionalidad por el momento)
                    _buildBotonOpcion(
                      titulo: 'Código Reserva',
                      subtitulo: null,
                      onTap: () {
                        _mostrarSnackBar('Funcionalidad de Reserva en desarrollo');
                      },
                    ),

                    const SizedBox(height: 20),

                    // 2. Botón Ingreso Directo (-1 cupo)
                    _buildBotonOpcion(
                      titulo: 'Ingreso Directo',
                      subtitulo: 'Botón para descontar cupos disponibles',
                      onTap: _isLoading ? null : () => _modificarCupos(-1),
                    ),

                    const SizedBox(height: 20),

                    // 3. Botón Liberar Cupo (+1 cupo)
                    _buildBotonOpcion(
                      titulo: 'Liberar Cupo',
                      subtitulo: '(Botón que agrega a cupos disponibles)',
                      onTap: _isLoading ? null : () => _modificarCupos(1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget reutilizable para mantener la estética de los botones en forma de tarjeta redondeada
  Widget _buildBotonOpcion({
    required String titulo,
    String? subtitulo,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.black,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitulo != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}