import 'dart:math';

int _contador = 0;
final Random _azar = Random();

/// Identificador único simple (suficiente para una app local).
String generarId() {
  _contador++;
  final tiempo = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final extra = _azar.nextInt(1 << 20).toRadixString(36);
  return '$tiempo-${_contador.toRadixString(36)}-$extra';
}
