import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Pone el [AppState] al alcance de todas las pantallas.
/// Con [of] la pantalla se vuelve a dibujar cuando el estado cambia (Observer).
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState notifier, required super.child})
      : super(notifier: notifier);

  /// Para usar dentro de build: se suscribe a los cambios.
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No se encontró AppScope en el árbol de widgets.');
    return scope!.notifier!;
  }

  /// Para usar en botones y eventos: no se suscribe.
  static AppState leer(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No se encontró AppScope en el árbol de widgets.');
    return scope!.notifier!;
  }
}
