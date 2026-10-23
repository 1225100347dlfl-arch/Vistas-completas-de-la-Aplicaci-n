import 'package:flutter/material.dart';

import '../core/fechas.dart';
import '../domain/entities/pedido.dart';
import '../domain/value_objects/estados.dart';
import '../domain/value_objects/rol.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/dashboard.dart';
import '../presentation/widgets/perfil_sheet.dart';
import 'rutas.dart';

/// Dashboard del REPARTIDOR: su próxima recolección y un resumen de sus pedidos.
class RepartidorHomeScreen extends StatelessWidget {
  const RepartidorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final nombre = app.usuario?.nombre ?? 'repartidor';
    final asignados = app.pedidosAsignados;
    final siguiente = app.siguienteRecoleccion;
    final pendientes = asignados.where((p) => p.estado.enCurso).length;
    final entregados = asignados.length - pendientes;

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
                  subtitulo: 'Tus recolecciones y entregas',
                  rol: RolUsuario.repartidor,
                  onPerfil: () => mostrarPerfil(context),
                ),
                const SizedBox(height: 22),
                if (siguiente == null)
                  const _SinPendientes()
                else
                  _HeroSiguiente(
                    pedido: siguiente,
                    cliente: app.usuarioPorId(siguiente.usuarioId)?.nombre ??
                        'Cliente',
                    onAtender: () => Navigator.of(context)
                        .pushNamed(rutaAtender, arguments: siguiente.id),
                  ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TarjetaStat(
                        icono: Icons.pending_actions_rounded,
                        valor: pendientes,
                        etiqueta: 'Por atender',
                        color: Tema.ambar,
                        fondo: Tema.ambarSuave,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TarjetaStat(
                        icono: Icons.check_circle_rounded,
                        valor: entregados,
                        etiqueta: 'Entregados',
                        color: Tema.verde,
                        fondo: Tema.verdeSuave,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AccesoLista(
                  icono: Icons.list_alt_rounded,
                  titulo: 'Mis pedidos',
                  subtitulo: asignados.isEmpty
                      ? 'Aún no tienes pedidos asignados'
                      : '${asignados.length} asignados en total',
                  onTap: () => Navigator.of(context).pushNamed(rutaMisPedidos),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSiguiente extends StatelessWidget {
  const _HeroSiguiente({
    required this.pedido,
    required this.cliente,
    required this.onAtender,
  });

  final Pedido pedido;
  final String cliente;
  final VoidCallback onAtender;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: Tema.degradado),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Pildora(
              texto: 'Siguiente recolección',
              icono: Icons.schedule_rounded,
              color: Colors.white,
              fondo: Colors.white.withAlpha(46),
            ),
            const SizedBox(height: 16),
            Text(
              formatoFechaHora(pedido.recoleccion),
              style: Tema.titulo(color: Colors.white, tamano: 28),
            ),
            const SizedBox(height: 6),
            Text(
              'Pedido #${pedido.numero} · $cliente',
              style:
                  Tema.cuerpo(color: Colors.white.withAlpha(230), tamano: 16),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_rounded,
                    size: 20, color: Colors.white.withAlpha(230)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pedido.direccion,
                    style: Tema.cuerpo(
                        color: Colors.white.withAlpha(230), tamano: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Estado: ${pedido.estado.etiqueta}',
              style:
                  Tema.cuerpo(color: Colors.white.withAlpha(200), tamano: 14),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAtender,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Atender pedido'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Tema.primario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vacío del dashboard: no hay recolecciones pendientes.
class _SinPendientes extends StatelessWidget {
  const _SinPendientes();

  @override
  Widget build(BuildContext context) {
    return LavaTarjeta(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const IconoBurbuja(icono: Icons.inbox_rounded, tamano: 64),
          const SizedBox(height: 14),
          Text('No tienes recolecciones pendientes',
              style: Tema.subtitulo(), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            'Cuando el administrador te asigne un pedido, aparecerá aquí.',
            textAlign: TextAlign.center,
            style: Tema.cuerpo(color: Tema.textoSuave, tamano: 14),
          ),
        ],
      ),
    );
  }
}
