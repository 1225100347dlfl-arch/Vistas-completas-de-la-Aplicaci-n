import 'package:flutter/material.dart';

/// Colores y estilos de LavaYa.
///
///  - AZUL  = la app, navegación y acciones principales (limpieza y confianza).
///  - VERDE = entregado / todo bien.
///  - ÁMBAR = en proceso / atención.
///  - ROJO  = error o algo que salió mal.
///
/// Estilo: fondo azul muy claro, tarjetas blancas con esquinas muy redondeadas,
/// sombras suaves y un degradado azul para lo más importante de cada pantalla.
class Tema {
  // Marca
  static const Color primario = Color(0xFF2362B0);
  static const Color primarioOscuro = Color(0xFF174682);
  static const Color primarioSuave = Color(0xFFEAF2FD);

  // Fondos y textos
  static const Color fondo = Color(0xFFF4F7FC);
  static const Color tarjeta = Colors.white;
  static const Color texto = Color(0xFF14213D);
  static const Color textoSuave = Color(0xFF5B6B84);
  static const Color borde = Color(0xFFDDE5F1);

  // Estados
  static const Color verde = Color(0xFF1E8E4E);
  static const Color verdeSuave = Color(0xFFE3F5EA);
  static const Color ambar = Color(0xFFB26A00);
  static const Color ambarSuave = Color(0xFFFFF3D6);
  static const Color rojo = Color(0xFFC62828);
  static const Color rojoSuave = Color(0xFFFDEAEA);
  static const Color estrella = Color(0xFFF5A623);

  static const LinearGradient degradado = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B55A0), Color(0xFF3D8BEA)],
  );

  static const List<BoxShadow> sombraSuave = [
    BoxShadow(color: Color(0x141B3A6B), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static TextStyle titulo({Color color = texto, double tamano = 26}) => TextStyle(
        fontSize: tamano,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.15,
      );

  static TextStyle subtitulo({Color color = texto, double tamano = 17}) => TextStyle(
        fontSize: tamano,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.25,
      );

  static TextStyle cuerpo({Color color = texto, double tamano = 15}) => TextStyle(
        fontSize: tamano,
        color: color,
        height: 1.35,
      );

  static TextStyle etiqueta({Color color = textoSuave}) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
      );
}

ThemeData construirTema() {
  final esquema = ColorScheme.fromSeed(
    seedColor: Tema.primario,
    primary: Tema.primario,
    error: Tema.rojo,
  );
  const redondeo = BorderRadius.all(Radius.circular(18));

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: Tema.fondo,
    textTheme: Typography.material2021().black.apply(
          bodyColor: Tema.texto,
          displayColor: Tema.texto,
        ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: const RoundedRectangleBorder(borderRadius: redondeo),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: const RoundedRectangleBorder(borderRadius: redondeo),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Tema.texto,
      contentTextStyle: TextStyle(color: Colors.white, fontSize: 15),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
    ),
  );
}
