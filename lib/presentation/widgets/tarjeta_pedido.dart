import 'package:flutter/material.dart';

import '../../core/fechas.dart';
import '../../domain/entities/pedido.dart';
import '../../domain/value_objects/estados.dart';
import '../tema.dart';
import 'componentes.dart';

/// Fila de las listas de pedidos del repartidor y del administrador.
/// [detalle] es una línea extra (dirección, cliente, repartidor...) y [pie]
/// un widget al final (por ejemplo un aviso "Sin repartidor").
class TarjetaPedidoResumen extends StatelessWidget {
  const TarjetaPedidoResumen({
    super.key,
    required this.pedido,
    required this.onTap,
    this.detalle,
    this.pie,
  });

  final Pedido pedido;
  final VoidCallback onTap;
  final String? detalle;
  final Widget? pie;

  @override
  Widget build(BuildContext context) {
    final entregado = pedido.estado == EstadoPedido.entregado;
    final definitivo = pedido.pesado || entregado;
    final total = pedido.totalVigente.texto;

    return LavaTarjeta(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Pedido #${pedido.numero}', style: Tema.subtitulo(tamano: 18)),
              ),
              Text(definitivo ? total : '$total aprox.', style: Tema.subtitulo(tamano: 18)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${formatoFechaHora(pedido.recoleccion)} · ${pedido.nombreServicio}',
            style: Tema.cuerpo(color: Tema.textoSuave, tamano: 14),
          ),
          if (detalle != null) ...[
            const SizedBox(height: 6),
            Text(detalle!, style: Tema.cuerpo(tamano: 14)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Pildora(
                texto: pedido.estado.etiqueta,
                color: entregado ? Tema.verde : Tema.ambar,
                fondo: entregado ? Tema.verdeSuave : Tema.ambarSuave,
              ),
              const Spacer(),
              if (pie != null) pie!,
            ],
          ),
        ],
      ),
    );
  }
}
