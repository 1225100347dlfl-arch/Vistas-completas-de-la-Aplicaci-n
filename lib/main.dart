import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'data/adapters/catalogo_local_adapter.dart';
import 'data/datos_demo.dart';
import 'data/local_lavaya_repository.dart';
import 'presentation/app_state.dart';
import 'screens/admin_pedidos_screen.dart';
import 'screens/admin_usuarios_screen.dart';
import 'screens/asignar_screen.dart';
import 'screens/atender_pedido_screen.dart';
import 'screens/calificacion_screen.dart';
import 'screens/confirmar_screen.dart';
import 'screens/historial_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/repartidor_pedidos_screen.dart';
import 'screens/rutas.dart';
import 'screens/seguimiento_screen.dart';
import 'screens/servicio_screen.dart';
import 'screens/splash_screen.dart';

/// Aquí se "arma" la app: se elige qué implementación usa cada pieza
/// y se registran las pantallas (carpeta lib/screens/).
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final repo = LocalLavaYaRepository();
  final appState = AppState(
    repo: repo,
    catalogo: CatalogoLocalAdapter(),
  );
  final inicializacion = Completer<void>();

  runApp(
    LavaYaApp(
      appState: appState,
      // Splashscreen -> (Login | dashboard según el tipo de usuario)
      home: SplashScreen(inicializacion: inicializacion.future),
      routes: {
        rutaRegistro: (_) => const RegistroScreen(),
        // Cliente
        rutaServicio: (_) => const ServicioScreen(),
        rutaConfirmar: (_) => const ConfirmarScreen(),
        rutaSeguimiento: (_) => const SeguimientoScreen(),
        rutaCalificar: (_) => const CalificacionScreen(),
        rutaHistorial: (_) => const HistorialScreen(),
        // Repartidor
        rutaMisPedidos: (_) => const RepartidorPedidosScreen(),
        rutaAtender: (_) => const AtenderPedidoScreen(),
        // Administrador
        rutaAdminPedidos: (_) => const AdminPedidosScreen(),
        rutaAdminUsuarios: (_) => const AdminUsuariosScreen(),
        rutaAsignar: (_) => const AsignarScreen(),
      },
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _inicializar(appState, repo).then(
      (_) => inicializacion.complete(),
      onError: inicializacion.completeError,
    );
  });
}

Future<void> _inicializar(AppState appState, LocalLavaYaRepository repo) async {
  await appState.iniciar();
  await sembrarDatosDemo(repo);
}
