import 'package:flutter/material.dart';

import '../core/fechas.dart';
import '../domain/entities/pedido.dart';
import '../domain/value_objects/estados.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import 'rutas.dart';

enum _Filtro { todos, enCurso, entregados }

/// 7. "Historial de pedidos": todos los pedidos, con filtro, y el atajo para calificar.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  _Filtro _filtro = _Filtro.todos;

  List<Pedido> _filtrar(List<Pedido> pedidos) {
    switch (_filtro) {
      case _Filtro.todos:
        return pedidos;
      case _Filtro.enCurso:
        return pedidos.where((p) => p.estado.enCurso).toList();
      case _Filtro.entregados:
        return pedidos.where((p) => !p.estado.enCurso).toList();
    }
  }

  void _pedirServicio() {
    AppScope.leer(context).prepararNuevoPedido();
    Navigator.of(context).pushNamed(rutaServicio);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final todos = app.pedidos;
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
                  titulo: 'Historial',
                  subtitulo: todos.length == 1 ? '1 pedido' : '${todos.length} pedidos',
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
                            label: Text(_nombreFiltro(f)),
                            selected: _filtro == f,
                            onSelected: (_) => setState(() => _filtro = f),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: lista.isEmpty
                      ? _Vacio(hayPedidos: todos.isNotEmpty, onPedir: _pedirServicio)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                          itemCount: lista.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, i) => _TarjetaPedido(pedido: lista[i]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _nombreFiltro(_Filtro f) {
    switch (f) {
      case _Filtro.todos:
        return 'Todos';
      case _Filtro.enCurso:
        return 'En curso';
      case _Filtro.entregados:
        return 'Entregados';
    }
  }
}

class _TarjetaPedido extends StatelessWidget {
  const _TarjetaPedido({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final entregado = pedido.estado == EstadoPedido.entregado;
    final nav = Navigator.of(context);

    Widget accion;
    if (entregado && !pedido.calificado) {
      accion = OutlinedButton(
        onPressed: () => nav.pushNamed(rutaCalificar, arguments: pedido.id),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        child: const Text('Calificar'),
      );
    } else if (pedido.calificado) {
      accion = EstrellasMini(valor: pedido.calificacion!);
    } else {
      accion = TextButton(
        onPressed: () => nav.pushNamed(rutaSeguimiento, arguments: pedido.id),
        child: const Text('Ver seguimiento'),
      );
    }

    return LavaTarjeta(
      padding: const EdgeInsets.all(16),
      onTap: () => nav.pushNamed(rutaSeguimiento, arguments: pedido.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Pedido #${pedido.numero}', style: Tema.subtitulo(tamano: 18)),
              ),
              Text(
                (entregado || pedido.pesado)
                    ? pedido.totalVigente.texto
                    : '${pedido.totalVigente.texto} aprox.',
                style: Tema.subtitulo(tamano: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${formatoFechaCorta(pedido.recoleccion)} · ${pedido.nombreServicio}',
            style: Tema.cuerpo(color: Tema.textoSuave, tamano: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Pildora(
                texto: pedido.estado.etiqueta,
                color: entregado ? Tema.verde : Tema.ambar,
                fondo: entregado ? Tema.verdeSuave : Tema.ambarSuave,
              ),
              const Spacer(),
              accion,
            ],
          ),
        ],
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.hayPedidos, required this.onPedir});

  /// true si hay pedidos pero el filtro no deja ver ninguno.
  final bool hayPedidos;
  final VoidCallback onPedir;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconoBurbuja(icono: Icons.history_rounded, tamano: 64),
            const SizedBox(height: 16),
            Text(
              hayPedidos ? 'No hay pedidos en esta lista' : 'Todavía no tienes pedidos',
              textAlign: TextAlign.center,
              style: Tema.subtitulo(),
            ),
            if (!hayPedidos) ...[
              const SizedBox(height: 6),
              Text(
                'Cuando hagas uno, aparecerá aquí.',
                style: Tema.cuerpo(color: Tema.textoSuave),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onPedir,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                ),
                child: const Text('Pedir servicio'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
