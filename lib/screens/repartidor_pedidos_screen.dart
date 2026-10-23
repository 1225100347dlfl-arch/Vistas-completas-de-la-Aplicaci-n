import 'package:flutter/material.dart';

import '../domain/entities/pedido.dart';
import '../domain/value_objects/estados.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/tarjeta_pedido.dart';
import 'rutas.dart';

enum _Filtro { todos, porAtender, entregados }

/// Lista principal del REPARTIDOR: los pedidos que le asignaron, con filtro
/// y estado vacío.
class RepartidorPedidosScreen extends StatefulWidget {
  const RepartidorPedidosScreen({super.key});

  @override
  State<RepartidorPedidosScreen> createState() => _RepartidorPedidosScreenState();
}

class _RepartidorPedidosScreenState extends State<RepartidorPedidosScreen> {
  _Filtro _filtro = _Filtro.todos;

  List<Pedido> _filtrar(List<Pedido> pedidos) {
    switch (_filtro) {
      case _Filtro.todos:
        return pedidos;
      case _Filtro.porAtender:
        return pedidos.where((p) => p.estado.enCurso).toList();
      case _Filtro.entregados:
        return pedidos.where((p) => !p.estado.enCurso).toList();
    }
  }

  String _nombre(_Filtro f) {
    switch (f) {
      case _Filtro.todos:
        return 'Todos';
      case _Filtro.porAtender:
        return 'Por atender';
      case _Filtro.entregados:
        return 'Entregados';
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final todos = app.pedidosAsignados;
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
                  titulo: 'Mis pedidos',
                  subtitulo: todos.length == 1 ? '1 pedido asignado' : '${todos.length} pedidos asignados',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
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
                            return TarjetaPedidoResumen(
                              pedido: p,
                              detalle: '$cliente · ${p.direccion}',
                              pie: p.estado.enCurso
                                  ? const Pildora(
                                      texto: 'Atender',
                                      icono: Icons.arrow_forward_rounded,
                                    )
                                  : null,
                              onTap: () =>
                                  Navigator.of(context).pushNamed(rutaAtender, arguments: p.id),
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
              hayPedidos ? 'No hay pedidos en esta lista' : 'No tienes pedidos asignados',
              textAlign: TextAlign.center,
              style: Tema.subtitulo(),
            ),
            if (!hayPedidos) ...[
              const SizedBox(height: 6),
              Text(
                'Cuando el administrador te asigne uno, aparecerá aquí.',
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
