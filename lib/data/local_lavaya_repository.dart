import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'memoria_lavaya_repository.dart';

/// Guarda todo en el celular (SharedPreferences) como un JSON.
/// Para sincronizar con internet se agregaría aquí una fuente remota,
/// sin cambiar las pantallas ni la lógica (ese es el objetivo del Repository).
class LocalLavaYaRepository extends MemoriaLavaYaRepository {
  static const String _clave = 'lavaya_bd_v2';

  SharedPreferences? _prefs;

  @override
  Future<void> inicializar() async {
    _prefs = await SharedPreferences.getInstance();
    final texto = _prefs!.getString(_clave);
    if (texto == null) return;
    try {
      cargarDesdeJson(jsonDecode(texto) as Map<String, dynamic>);
    } catch (_) {
      // Datos dañados: se empieza vacío en lugar de cerrar la app.
    }
  }

  @override
  Future<void> persistir() async {
    await _prefs?.setString(_clave, jsonEncode(aJson()));
  }
}
