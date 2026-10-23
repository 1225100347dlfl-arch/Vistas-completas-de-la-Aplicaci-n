import 'package:flutter/material.dart';

import '../core/fechas.dart';
import '../core/formato.dart';
import '../domain/entities/pedido.dart';
import '../domain/entities/usuario.dart';
import '../domain/value_objects/estados.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';

/// Detalle de un pedido para el ADMINISTRADOR, con su formulario:
/// elegir (o cambiar) el repartidor que lo va a atender.
/// Recibe como argumento de la ruta el id del pedido.
class AsignarScreen extends StatefulWidget {
  const AsignarScreen({super.key});

  @override
  State<AsignarScreen> createState() => _AsignarScreenState();
}

class _AsignarScreenState extends State<AsignarScreen> {
  String? _eleccion;
  bool _tocado = false;
  bool _guardando = false;
  String? _error;

  Future<void> _asignar(String pedidoId, String repartidorId) async {
    final app = AppScope.leer(context);
    final mensajes = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() {
      _guardando = true;
      _error = null;
    });
    final error = await app.asignarRepartidor(pedidoId, repartidorId);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _guardando = false;
        _error = error;
      });
      return;
    }
    final nombre = app.usuarioPorId(repartidorId)?.nombre ?? 'el repartidor';
    nav.pop();
    mensajes
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Pedido asignado a $nombre.')));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final id = ModalRoute.of(context)?.settings.arguments;
    final pedido = id is String ? app.pedido(id) : null;
    final cliente = pedido == null ? null : app.usuarioPorId(pedido.usuarioId);
    final actual = (pedido == null || pedido.repartidorId == null)
        ? null
        : app.usuarioPorId(pedido.repartidorId!);
    final repartidores = app.repartidores;
    final seleccionado = _tocado ? _eleccion : pedido?.repartidorId;

    return Scaffold(
      backgroundColor: Tema.fondo,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                CabeceraPantalla(
                  titulo: 'Asignar repartidor',
                  subtitulo: pedido == null ? null : 'Pedido #${pedido.numero}',
                ),
                Expanded(
                  child: pedido == null
                      ? Center(
                          child: Text(
                            'No encontramos ese pedido.',
                            style: Tema.cuerpo(color: Tema.textoSuave),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                          children: [
                            _Resumen(
                              pedido: pedido,
                              cliente: cliente?.nombre ?? 'Cliente',
                              repartidor: actual?.nombre,
                            ),
                            const SizedBox(height: 16),
                            if (!pedido.estado.enCurso)
                              const _Aviso(
                                texto: 'Este pedido ya se entregó, no se puede reasignar.',
                              )
                            else if (repartidores.isEmpty)
                              const _Aviso(
                                texto:
                                    'No hay repartidores registrados. Crea una cuenta de tipo Repartidor.',
                              )
                            else
                              LavaTarjeta(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Repartidor', style: Tema.subtitulo()),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Elige quién va a recoger y entregar este pedido.',
                                      style: Tema.cuerpo(color: Tema.textoSuave, tamano: 13.5),
                                    ),
                                    const SizedBox(height: 14),
                                    for (final r in repartidores)
                                      _OpcionRepartidor(
                                        usuario: r,
                                        pendientes: app.todosLosPedidos
                                            .where((p) => p.repartidorId == r.id && p.estado.enCurso)
                                            .length,
                                        seleccionado: seleccionado == r.id,
                                        onTap: () => setState(() {
                                          _tocado = true;
                                          _eleccion = r.id;
                                        }),
                                      ),
                                    if (_error != null) ...[
                                      const SizedBox(height: 6),
                                      MensajeError(_error!),
                                    ],
                                    const SizedBox(height: 6),
                                    FilledButton(
                                      onPressed: (seleccionado == null ||
                                              seleccionado == pedido.repartidorId ||
                                              _guardando)
                                          ? null
                                          : () => _asignar(pedido.id, seleccionado),
                                      child: _guardando
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(strokeWidth: 3),
                                            )
                                          : Text(
                                              pedido.asignado
                                                  ? 'Cambiar repartidor'
                                                  : 'Asignar repartidor',
                                            ),
                                    ),
                                  ],
                                ),
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

class _Resumen extends StatelessWidget {
  const _Resumen({required this.pedido, required this.cliente, required this.repartidor});

  final Pedido pedido;
  final String cliente;
  final String? repartidor;

  @override
  Widget build(BuildContext context) {
    final entregado = pedido.estado == EstadoPedido.entregado;
    return LavaTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Detalle del pedido', style: Tema.subtitulo())),
              Pildora(
                texto: pedido.estado.etiqueta,
                color: entregado ? Tema.verde : Tema.ambar,
                fondo: entregado ? Tema.verdeSuave : Tema.ambarSuave,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Dato(icono: Icons.person_rounded, titulo: 'Cliente', valor: cliente),
          _Dato(icono: Icons.location_on_rounded, titulo: 'Dirección', valor: pedido.direccion),
          _Dato(
            icono: Icons.event_rounded,
            titulo: 'Recolección',
            valor: formatoFechaHora(pedido.recoleccion),
          ),
          _Dato(
            icono: Icons.local_laundry_service_rounded,
            titulo: 'Servicio',
            valor: pedido.pesado
                ? '${pedido.nombreServicio} · ${formatoKilos(pedido.kilosReales!)} kg (peso real)'
                : '${pedido.nombreServicio} · ${pedido.kilos} kg aprox.',
          ),
          _Dato(
            icono: Icons.delivery_dining_rounded,
            titulo: 'Repartidor actual',
            valor: repartidor ?? 'Sin asignar',
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

class _OpcionRepartidor extends StatelessWidget {
  const _OpcionRepartidor({
    required this.usuario,
    required this.pendientes,
    required this.seleccionado,
    required this.onTap,
  });

  final Usuario usuario;
  final int pendientes;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: seleccionado,
        label: 'Repartidor ${usuario.nombre}, $pendientes pedidos por atender',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: seleccionado ? Tema.primarioSuave : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: seleccionado ? Tema.primario : Tema.borde,
              width: seleccionado ? 2 : 1.2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: seleccionado ? Colors.white : Tema.primarioSuave,
                      child: Text(
                        usuario.nombre.isEmpty ? '?' : usuario.nombre[0].toUpperCase(),
                        style: Tema.subtitulo(color: Tema.primario),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(usuario.nombre, style: Tema.subtitulo(tamano: 16)),
                          Text(
                            pendientes == 1 ? '1 pedido por atender' : '$pendientes pedidos por atender',
                            style: Tema.cuerpo(color: Tema.textoSuave, tamano: 13),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      seleccionado
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: seleccionado ? Tema.primario : Tema.borde,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Tema.ambarSuave,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Tema.ambar),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: Tema.cuerpo(tamano: 14.5))),
        ],
      ),
    );
  }
}
