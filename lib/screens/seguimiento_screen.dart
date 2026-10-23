import 'package:flutter/material.dart';

import '../core/fechas.dart';
import '../core/formato.dart';
import '../domain/entities/pedido.dart';
import '../domain/value_objects/estados.dart';
import '../domain/value_objects/rol.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/mapa_seguimiento.dart';
import 'rutas.dart';

const List<EstadoPedido> _etapas = [
  EstadoPedido.recogido,
  EstadoPedido.enProceso,
  EstadoPedido.enCamino,
  EstadoPedido.entregado,
];

/// 5. "Mapa / Seguimiento": dónde va el pedido, en qué etapa está y cuánto falta.
/// Recibe como argumento de la ruta el id del pedido.
class SeguimientoScreen extends StatelessWidget {
  const SeguimientoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final id = ModalRoute.of(context)?.settings.arguments;
    final pedido = id is String ? app.pedido(id) : null;

    return Scaffold(
      backgroundColor: Tema.fondo,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                CabeceraPantalla(
                  titulo: 'Seguimiento',
                  subtitulo: pedido == null ? null : 'Pedido #${pedido.numero}',
                ),
                Expanded(
                  child: pedido == null
                      ? const _NoEncontrado()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: SizedBox(
                                height: 280,
                                width: double.infinity,
                                child: MapaSeguimiento(estado: pedido.estado),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _PanelEstado(
                              pedido: pedido,
                              mostrarDemo: app.rol == RolUsuario.cliente && app.puedeAvanzar(pedido),
                              onAvanzar: () => app.avanzarEstado(pedido.id),
                              onCalificar: () => Navigator.of(context)
                                  .pushNamed(rutaCalificar, arguments: pedido.id),
                            ),
                            const SizedBox(height: 16),
                            _Detalle(
                              pedido: pedido,
                              repartidor: pedido.repartidorId == null
                                  ? null
                                  : app.usuarioPorId(pedido.repartidorId!)?.nombre,
                            ),
                          ],
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

class _NoEncontrado extends StatelessWidget {
  const _NoEncontrado();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('No encontramos ese pedido.', style: Tema.cuerpo(color: Tema.textoSuave)),
    );
  }
}

class _PanelEstado extends StatelessWidget {
  const _PanelEstado({
    required this.pedido,
    required this.mostrarDemo,
    required this.onAvanzar,
    required this.onCalificar,
  });

  final Pedido pedido;

  /// El botón de simulación solo lo ve el cliente dueño del pedido.
  final bool mostrarDemo;
  final VoidCallback onAvanzar;
  final VoidCallback onCalificar;

  @override
  Widget build(BuildContext context) {
    final entregado = pedido.estado == EstadoPedido.entregado;
    return LavaTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Estado del pedido', style: Tema.subtitulo())),
              Pildora(
                texto: pedido.estado.etiqueta,
                color: entregado ? Tema.verde : Tema.primario,
                fondo: entregado ? Tema.verdeSuave : Tema.primarioSuave,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Etapas(estado: pedido.estado),
          const SizedBox(height: 18),
          if (entregado)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Tema.verdeSuave,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Tema.verde),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '¡Tu ropa ya está en casa!',
                      style: Tema.subtitulo(color: Tema.verde, tamano: 16),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Tema.primarioSuave,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Tiempo estimado', style: Tema.cuerpo(color: Tema.textoSuave)),
                  ),
                  Text(
                    '${pedido.estado.minutosRestantes} min',
                    style: Tema.titulo(color: Tema.primario, tamano: 22),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (!entregado && mostrarDemo) ...[
            OutlinedButton.icon(
              onPressed: onAvanzar,
              icon: const Icon(Icons.fast_forward_rounded),
              label: const Text('Avanzar etapa (demo)'),
            ),
            const SizedBox(height: 8),
            Text(
              'Simulación para la demostración. En el flujo real avanza el repartidor.',
              style: Tema.cuerpo(color: Tema.textoSuave, tamano: 12.5),
            ),
          ] else if (entregado && !pedido.calificado)
            FilledButton.icon(
              onPressed: onCalificar,
              icon: const Icon(Icons.star_rounded),
              label: const Text('Calificar servicio'),
            )
          else if (pedido.calificado)
            Row(
              children: [
                Text('Tu calificación', style: Tema.cuerpo(color: Tema.textoSuave)),
                const SizedBox(width: 10),
                EstrellasMini(valor: pedido.calificacion!, tamano: 22),
              ],
            ),
        ],
      ),
    );
  }
}

/// Las 4 etapas con una línea que se va llenando de azul.
class _Etapas extends StatelessWidget {
  const _Etapas({required this.estado});

  final EstadoPedido estado;

  bool _alcanzada(EstadoPedido etapa) => estado.index >= etapa.index;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _etapas.length; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        color: i == 0
                            ? Colors.transparent
                            : (_alcanzada(_etapas[i]) ? Tema.primario : Tema.borde),
                      ),
                    ),
                    _Punto(alcanzada: _alcanzada(_etapas[i]), actual: estado == _etapas[i]),
                    Expanded(
                      child: Container(
                        height: 4,
                        color: i == _etapas.length - 1
                            ? Colors.transparent
                            : (_alcanzada(_etapas[i + 1]) ? Tema.primario : Tema.borde),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _etapas[i].etiqueta,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: estado == _etapas[i] ? FontWeight.w800 : FontWeight.w600,
                    color: _alcanzada(_etapas[i]) ? Tema.texto : Tema.textoSuave,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({required this.alcanzada, required this.actual});

  final bool alcanzada;
  final bool actual;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: actual ? 24 : 18,
      height: actual ? 24 : 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: alcanzada ? Tema.primario : Colors.white,
        border: Border.all(
          color: alcanzada ? Tema.primario : Tema.borde,
          width: 3,
        ),
        boxShadow: actual
            ? [BoxShadow(color: Tema.primario.withAlpha(70), blurRadius: 10, spreadRadius: 3)]
            : const <BoxShadow>[],
      ),
      child: alcanzada
          ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
          : null,
    );
  }
}

class _Detalle extends StatelessWidget {
  const _Detalle({required this.pedido, this.repartidor});

  final Pedido pedido;

  /// Nombre del repartidor asignado, si ya hay uno.
  final String? repartidor;

  @override
  Widget build(BuildContext context) {
    final definitivo = pedido.estado == EstadoPedido.entregado || pedido.pesado;
    return LavaTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detalle del pedido', style: Tema.subtitulo()),
          const SizedBox(height: 14),
          _Dato(
            icono: Icons.local_laundry_service_rounded,
            titulo: 'Servicio',
            valor: pedido.pesado
                ? '${pedido.nombreServicio} · ${formatoKilos(pedido.kilosReales!)} kg (peso real)'
                : '${pedido.nombreServicio} · ${pedido.kilos} kg aprox.',
          ),
          if (repartidor != null)
            _Dato(
              icono: Icons.delivery_dining_rounded,
              titulo: 'Repartidor',
              valor: repartidor!,
            ),
          _Dato(
            icono: Icons.event_rounded,
            titulo: 'Recolección',
            valor: formatoFechaHora(pedido.recoleccion),
          ),
          _Dato(
            icono: Icons.location_on_rounded,
            titulo: 'Dirección',
            valor: pedido.direccion,
          ),
          if (pedido.notas != null)
            _Dato(
              icono: Icons.sticky_note_2_rounded,
              titulo: 'Notas',
              valor: pedido.notas!,
            ),
          _Dato(
            icono: Icons.payments_rounded,
            titulo: definitivo ? 'Total' : 'Total estimado',
            valor: definitivo
                ? pedido.totalVigente.texto
                : '${pedido.totalVigente.texto} aprox.',
            ultimo: true,
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.ultimo = false,
  });

  final IconData icono;
  final String titulo;
  final String valor;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 22, color: Tema.primario),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Tema.etiqueta()),
                const SizedBox(height: 2),
                Text(valor, style: Tema.cuerpo(tamano: 15.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
