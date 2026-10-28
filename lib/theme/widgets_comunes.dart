import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Tarjeta blanca muy redondeada, base de las pantallas.
class TarjetaBlanca extends StatelessWidget {
  const TarjetaBlanca({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.superficie,
      borderRadius: BorderRadius.circular(28),
    ),
    child: child,
  );
}

/// Logo y nombre de la app para las pantallas de acceso.
class EncabezadoMarca extends StatelessWidget {
  const EncabezadoMarca({super.key, required this.subtitulo});
  final String subtitulo;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.oscuro,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.local_parking, color: Colors.white, size: 38),
      ),
      const SizedBox(height: 18),
      const Text(
        'ParkFinder',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(
        subtitulo,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textoSuave, fontSize: 14),
      ),
    ],
  );
}

/// Mensaje de error destacado.
class AvisoError extends StatelessWidget {
  const AvisoError({super.key, required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.errorSuave,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Indicador dentro de un botón mientras se espera al servidor.
class CargandoEnBoton extends StatelessWidget {
  const CargandoEnBoton({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 20,
    width: 20,
    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
  );
}
