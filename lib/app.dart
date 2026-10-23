import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'presentation/app_scope.dart';
import 'presentation/app_state.dart';
import 'presentation/tema.dart';

class LavaYaApp extends StatelessWidget {
  const LavaYaApp({
    super.key,
    required this.appState,
    required this.home,
    this.routes = const {},
  });

  final AppState appState;

  /// Pantalla inicial; se define desde main.dart.
  final Widget home;

  /// Rutas con nombre (se definen en main.dart).
  final Map<String, WidgetBuilder> routes;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: appState,
      child: MaterialApp(
        title: 'LavaYa',
        debugShowCheckedModeBanner: false,
        theme: construirTema(),
        locale: const Locale('es', 'MX'),
        supportedLocales: const [Locale('es', 'MX'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: home,
        routes: routes,
      ),
    );
  }
}
