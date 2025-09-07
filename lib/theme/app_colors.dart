import 'package:flutter/material.dart';

/// Clase que define la paleta de colores corporativos para la aplicación.
/// Basados en los colores de la Universidad Católica de Temuco.
class AppColors {
  // Colores primarios
  static const Color azulPrimario = Color(0xFF0075B4);    // #0075B4 - Azul institucional
  static const Color amarilloPrimario = Color(0xFFEDC500); // #EDC500 - Amarillo institucional
  static const Color grisPrimario = Color(0xFF878787);     // #878787 - Gris institucional
  static const Color blanco = Color(0xFFFFFFFF);           // #FFFFFF - Blanco
  
  // Variaciones de los colores primarios (tonos más claros y oscuros)
  static const Color azulClaro = Color(0xFF0095E4);       // Variación clara del azul
  static const Color azulOscuro = Color(0xFF005584);      // Variación oscura del azul
  
  static const Color amarilloClaro = Color(0xFFFDD835);   // Variación clara del amarillo
  static const Color amarilloOscuro = Color(0xFFD4AF00);  // Variación oscura del amarillo
  
  static const Color grisClaro = Color(0xFFB0B0B0);       // Variación clara del gris
  static const Color grisOscuro = Color(0xFF4A4A4A);      // Variación oscura del gris
  
  // Colores para estados específicos
  static const Color exito = Color(0xFF4CAF50);           // Color para mensajes de éxito
  static const Color error = Color(0xFFE53935);           // Color para mensajes de error
  static const Color advertencia = Color(0xFFFF9800);     // Color para mensajes de advertencia
  
  // Colores para fondos
  static const Color fondoClaro = Color(0xFFF5F5F5);      // Fondo claro para la aplicación
  static const Color fondoOscuro = Color(0xFF303030);     // Fondo oscuro para modo nocturno
  
  // Color de acento (para destacar elementos interactivos)
  static const Color acento = azulPrimario;
  
  // Colores para botones
  static const Color botonPrimario = azulPrimario;
  static const Color botonSecundario = amarilloPrimario;
  
  // Colores para textos
  static const Color textoOscuro = grisOscuro;
  static const Color textoClaro = blanco;
  static const Color textoSecundario = grisPrimario;
}
