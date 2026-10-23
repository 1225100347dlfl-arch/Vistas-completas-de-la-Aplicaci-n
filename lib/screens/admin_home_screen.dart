import 'package:flutter/material.dart';

import '../domain/value_objects/estados.dart';
import '../domain/value_objects/rol.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/dashboard.dart';
import '../presentation/widgets/perfil_sheet.dart';
import 'rutas.dart';

/// Dashboard del ADMINISTRADOR: resumen de toda la operación y accesos a las listas.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final nombre = app.usuario?.nombre ?? 'admin';
    final pedidos = app.todosLosPedidos;
    final enCurso = pedidos.where((p) => p.estado.enCurso).toList();
    final sinAsignar = enCurso.where((p) => !p.asignado).length;
    final repartidores = app.repartidores.length;

    return Scaffold(
      backgroundColor: Tema.fondo,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                EncabezadoDashboard(
                  nombre: nombre,
                  subtitulo: 'Así va la operación',
                  rol: RolUsuario.admin,
                  onPerfil: () => mostrarPerfil(context),
                ),
                const SizedBox(height: 22),
                if (sinAsignar > 0) ...[
                  _AvisoSinAsignar(
                    cantidad: sinAsignar,
                    onVer: () => Navigator.of(context).pushNamed(rutaAdminPedidos),
                  ),
                  const SizedBox(height: 18),
                ],
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: TarjetaStat(
                          icono: Icons.receipt_long_rounded,
                          valor: pedidos.length,
                          etiqueta: 'Pedidos en total',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TarjetaStat(
                          icono: Icons.local_shipping_rounded,
                          valor: enCurso.length,
                          etiqueta: 'En curso',
                          color: Tema.ambar,
                          fondo: Tema.ambarSuave,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: TarjetaStat(
                          icono: Icons.person_off_rounded,
                          valor: sinAsignar,
                          etiqueta: 'Sin repartidor',
                          color: sinAsignar > 0 ? Tema.rojo : Tema.verde,
                          fondo: sinAsignar > 0 ? Tema.rojoSuave : Tema.verdeSuave,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TarjetaStat(
                          icono: Icons.delivery_dining_rounded,
                          valor: repartidores,
                          etiqueta: 'Repartidores',
                          color: Tema.verde,
                          fondo: Tema.verdeSuave,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AccesoLista(
                  icono: Icons.list_alt_rounded,
                  titulo: 'Pedidos',
                  subtitulo: 'Ver todos y asignar repartidor',
                  onTap: () => Navigator.of(context).pushNamed(rutaAdminPedidos),
                ),
                const SizedBox(height: 12),
                AccesoLista(
                  icono: Icons.group_rounded,
                  titulo: 'Usuarios',
                  subtitulo: 'Clientes, repartidores y administradores',
                  onTap: () => Navigator.of(context).pushNamed(rutaAdminUsuarios),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvisoSinAsignar extends StatelessWidget {
  const _AvisoSinAsignar({required this.cantidad, required this.onVer});

  final int cantidad;
  final VoidCallback onVer;

  @override
  Widget build(BuildContext context) {
    return LavaTarjeta(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      color: Tema.ambarSuave,
      bordeColor: Tema.ambar.withAlpha(70),
      onTap: onVer,
      child: Row(
        children: [
          const IconoBurbuja(
            icono: Icons.warning_amber_rounded,
            color: Tema.ambar,
            fondo: Colors.white,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              cantidad == 1
                  ? 'Hay 1 pedido sin repartidor'
                  : 'Hay $cantidad pedidos sin repartidor',
              style: Tema.subtitulo(tamano: 16),
            ),
          ),
          TextButton(onPressed: onVer, child: const Text('Asignar')),
        ],
      ),
    );
  }
}
