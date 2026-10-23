import 'package:flutter/material.dart';

import '../domain/value_objects/rol.dart';
import '../presentation/app_scope.dart';
import 'admin_home_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'repartidor_home_screen.dart';

/// Decide qué pantalla mostrar: el Login si no hay sesión, o el dashboard
/// que le toca a cada tipo de usuario (cliente, repartidor o administrador).
/// Se actualiza sola cuando alguien entra o cierra sesión (Observer).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = AppScope.of(context).usuario;
    if (usuario == null) return const LoginScreen();
    switch (usuario.rol) {
      case RolUsuario.cliente:
        return const HomeScreen();
      case RolUsuario.repartidor:
        return const RepartidorHomeScreen();
      case RolUsuario.admin:
        return const AdminHomeScreen();
    }
  }
}
