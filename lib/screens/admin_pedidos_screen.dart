import 'package:flutter/material.dart';

import '../domain/entities/pedido.dart';
import '../domain/value_objects/estados.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/tarjeta_pedido.dart';
import 'rutas.dart';

enum _Filtro { todos, sinRepartidor, enCurso, entregados }

/// Lista principal del ADMINISTRADOR: todos los pedidos de todos los clientes,
/// con filtro y estado vacío. Al tocar uno se abre el formulario para asignar repartidor.
class AdminPedidosScreen extends StatefulWidget {
  const AdminPedidosScreen({super.key});

  @override
  State<AdminPedidosScreen> createState() => _AdminPedidosScreenState();
}

class _AdminPedidosScreenState extends State<AdminPedidosScreen> {
  _Filtro _filtro = _Filtro.todos;

  List<Pedido> _filtrar(List<Pedido> pedidos) {
    switch (_filtro) {
      case _Filtro.todos:
        return pedidos;
      case _Filtro.sinRepartidor:
        return pedidos.where((p) => p.estado.enCurso && !p.asignado).toList();
      case _Filtro.enCurso:
        return pedidos.where((p) => p.estado.enCurso).toList();
      case _Filtro.entregados:
        return pedidos.where((p) => !p.estado.enCurso).toList();
    }
  }

  String _nombre(_Filtro f) {
    switch (f) {
      case _Filtro.todos:
        return 'Todos';
      case _Filtro.sinRepartidor:
        return 'Sin repartidor';
      case _Filtro.enCurso:
        return 'En curso';
      case _Filtro.entregados:
        return 'Entregados';
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final todos = app.todosLosPedidos;
    final lista = _filtrar(todos);

    return Scaffold(
      backgroundColor: Tema.fondo,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                CabeceraPantalla(
                  titulo: 'Pedidos',
                  subtitulo: todos.length == 1 ? '1 pedido en total' : '${todos.length} pedidos en total',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final f in _Filtro.values)
                          ChoiceChip(
                            label: Text(_nombre(f)),
                            selected: _filtro == f,
                            onSelected: (_) => setState(() => _filtro = f),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: lista.isEmpty
                      ? _Vacio(hayPedidos: todos.isNotEmpty)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                          itemCount: lista.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, i) {
                            final p = lista[i];
                            final cliente = app.usuarioPorId(p.usuarioId)?.nombre ?? 'Cliente';
                            final repartidor = p.repartidorId == null
                                ? null
                                : app.usuarioPorId(p.repartidorId!)?.nombre;
                            return TarjetaPedidoResumen(
                              pedido: p,
                              detalle: 'Cliente: $cliente · Repartidor: ${repartidor ?? 'sin asignar'}',
                              pie: (p.estado.enCurso && !p.asignado)
                                  ? const Pildora(
                                      texto: 'Sin repartidor',
                                      icono: Icons.person_off_rounded,
                                      color: Tema.rojo,
                                      fondo: Tema.rojoSuave,
                                    )
                                  : null,
                              onTap: () =>
                                  Navigator.of(context).pushNamed(rutaAsignar, arguments: p.id),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.hayPedidos});

  /// true si hay pedidos pero el filtro no deja ver ninguno.
  final bool hayPedidos;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconoBurbuja(icono: Icons.inbox_rounded, tamano: 64),
            const SizedBox(height: 16),
            Text(
              hayPedidos ? 'No hay pedidos en esta lista' : 'Todavía no hay pedidos',
              textAlign: TextAlign.center,
              style: Tema.subtitulo(),
            ),
            if (!hayPedidos) ...[
              const SizedBox(height: 6),
              Text(
                'Cuando un cliente haga uno, aparecerá aquí.',
                textAlign: TextAlign.center,
                style: Tema.cuerpo(color: Tema.textoSuave),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
