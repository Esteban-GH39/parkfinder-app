import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta y estilos compartidos, según el diseño de referencia que acordó el equipo
/// (fondo gris azulado, tarjetas blancas, acentos negros y azul).
class AppColors {
  static const oscuro = Color(0xFF211F1F);
  static const acento = Color(0xFF2B8FE0);
  static const acentoSuave = Color(0xFFDCEBFA);
  static const fondo = Color(0xFFEEF0F7);
  static const superficie = Colors.white;
  static const chip = Color(0xFFE1E4EC);
  static const texto = Color(0xFF211F1F);
  static const textoSuave = Color(0xFF8A8FA0);
  static const borde = Color(0xFFE3E6EE);
  static const exito = Color(0xFF2D8A5A);
  static const exitoSuave = Color(0xFFDDF3E6);
  static const error = Color(0xFFC43D2F);
  static const errorSuave = Color(0xFFFBEAE8);
  static const lila = Color(0xFFE6E0FA);
}

class AppTheme {
  static ThemeData get claro {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.acento,
      primary: AppColors.oscuro,
      surface: AppColors.superficie,
      error: AppColors.error,
    );
    final texto = GoogleFonts.poppinsTextTheme().apply(
      bodyColor: AppColors.texto,
      displayColor: AppColors.texto,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: AppColors.fondo,
      textTheme: texto,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.fondo,
        foregroundColor: AppColors.texto,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: texto.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          color: AppColors.texto,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fondo,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: AppColors.textoSuave),
        labelStyle: const TextStyle(color: AppColors.textoSuave),
        prefixIconColor: AppColors.textoSuave,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.oscuro, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.oscuro,
          textStyle: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.oscuro,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.oscuro,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.chip,
          disabledForegroundColor: AppColors.textoSuave,
          elevation: 0,
          minimumSize: const Size.fromHeight(58),
          shape: const StadiumBorder(),
          textStyle: texto.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.oscuro,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.chip,
          disabledForegroundColor: AppColors.textoSuave,
          minimumSize: const Size.fromHeight(58),
          shape: const StadiumBorder(),
          textStyle: texto.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
