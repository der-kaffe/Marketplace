import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Clase que define los temas para la aplicación.
/// Utiliza los colores definidos en AppColors.
class AppTheme {
  /// Tema claro para la aplicación
  static ThemeData get lightTheme {
    return ThemeData(
      // Definimos el esquema de colores basado en los colores corporativos
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.azulPrimario,
        onPrimary: AppColors.blanco,
        secondary: AppColors.amarilloPrimario,
        onSecondary: AppColors.grisOscuro,
        tertiary: AppColors.grisPrimario,
        onTertiary: AppColors.blanco,
        error: AppColors.error,
        onError: AppColors.blanco,
        surface: AppColors.blanco,
        onSurface: AppColors.textoOscuro,
      ),
      
      // Configuramos las propiedades Material 3
      useMaterial3: true,
      
      // Configuración para AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.azulPrimario,
        foregroundColor: AppColors.blanco,
        elevation: 0,
      ),
      
      // Configuración para botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.botonPrimario,
          foregroundColor: AppColors.blanco,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      
      // Configuración para botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.azulPrimario,
        ),
      ),
      
      // Configuración para botones con contorno
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.azulPrimario,
          side: const BorderSide(color: AppColors.azulPrimario),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      
      // Configuración para campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blanco,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.grisPrimario),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.azulPrimario, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.grisClaro),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.textoSecundario),
      ),
        // Configuración para tarjetas
      cardTheme: CardThemeData(
        color: AppColors.blanco,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Estilo de texto para cabeceras y párrafos
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textoOscuro,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: AppColors.textoOscuro,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: AppColors.textoOscuro,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textoOscuro,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: AppColors.textoOscuro),
        bodyMedium: TextStyle(color: AppColors.textoOscuro),
      ),
      
      // Iconos con el color primario
      iconTheme: const IconThemeData(
        color: AppColors.azulPrimario,
      ),
    );
  }

  /// Tema oscuro para la aplicación (si decides implementarlo más adelante)
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.azulPrimario,
        onPrimary: AppColors.blanco,
        secondary: AppColors.amarilloPrimario,
        onSecondary: AppColors.grisOscuro,
        tertiary: AppColors.grisPrimario,
        onTertiary: AppColors.blanco,
        error: AppColors.error,
        onError: AppColors.blanco,
        surface: Color(0xFF424242),
        onSurface: AppColors.textoClaro,
      ),
      useMaterial3: true,
      // Puedes configurar más propiedades para el tema oscuro cuando decidas implementarlo
    );
  }
}
