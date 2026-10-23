import 'package:flutter/material.dart';

import '../core/fechas.dart';
import '../core/formato.dart';
import '../domain/entities/pedido.dart';
import '../domain/value_objects/estados.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';

/// Detalle de un pedido para el REPARTIDOR, con su formulario: registrar el peso
/// real de la ropa (el total se recalcula) y avanzar de etapa.
/// Recibe como argumento de la ruta el id del pedido.
class AtenderPedidoScreen extends StatefulWidget {
  const AtenderPedidoScreen({super.key});

  @override
  State<AtenderPedidoScreen> createState() => _AtenderPedidoScreenState();
}

class _AtenderPedidoScreenState extends State<AtenderPedidoScreen> {
  final _form = GlobalKey<FormState>();
  final _peso = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _peso.dispose();
    super.dispose();
  }

  /// Acepta "4.5" y "4,5".
  double? _leerPeso(String? texto) => double.tryParse((texto ?? '').trim().replaceAll(',', '.'));

  String? _validarPeso(String? texto) {
    final kilos = _leerPeso(texto);
    if (kilos == null) return 'Escribe el peso en kilos (por ejemplo 4.5).';
    if (kilos < Pedido.pesoMinimo || kilos > Pedido.pesoMaximo) {
      return 'El peso debe estar entre 0.5 y 30 kg.';
    }
    return null;
  }

  Future<void> _guardarPeso(String pedidoId) async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final kilos = _leerPeso(_peso.text);
    if (kilos == null) return;
    final app = AppScope.leer(context);
    final mensajes = ScaffoldMessenger.of(context);
    setState(() {
      _guardando = true;
      _error = null;
    });
    final error = await app.registrarPeso(pedidoId, kilos);
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _error = error;
    });
    if (error != null) return;
    final actualizado = app.pedido(pedidoId);
    _peso.clear();
    FocusScope.of(context).unfocus();
    mensajes
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            actualizado == null || actualizado.kilosReales == null
                ? 'Peso guardado.'
                : 'Peso guardado: ${formatoKilos(actualizado.kilosReales!)} kg · '
                    'Total ${actualizado.totalVigente.texto}',
          ),
        ),
      );
  }

  Future<void> _avanzar(String pedidoId) async {
    final app = AppScope.leer(context);
    final mensajes = ScaffoldMessenger.of(context);
    await app.avanzarEstado(pedidoId);
    final p = app.pedido(pedidoId);
    if (p == null) return;
    mensajes
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('El pedido pasó a: ${p.estado.etiqueta}')));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final id = ModalRoute.of(context)?.settings.arguments;
    final pedido = id is String ? app.pedido(id) : null;
    final cliente = pedido == null ? null : app.usuarioPorId(pedido.usuarioId);
    final propio = pedido != null && app.puedeAvanzar(pedido);

    return Scaffold(
      backgroundColor: Tema.fondo,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                CabeceraPantalla(
                  titulo: 'Atender pedido',
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
                              nombreCliente: cliente?.nombre ?? 'Cliente',
                              contactoCliente: cliente?.contacto.valor,
                            ),
                            const SizedBox(height: 16),
                            if (pedido.estado.enCurso && propio) ...[
                              _FormularioPeso(
                                form: _form,
                                controller: _peso,
                                pedido: pedido,
                                guardando: _guardando,
                                error: _error,
                                validar: _validarPeso,
                                leerPeso: _leerPeso,
                                onGuardar: () => _guardarPeso(pedido.id),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () => _avanzar(pedido.id),
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: Text('Marcar como: ${pedido.estado.siguiente!.etiqueta}'),
                              ),
                            ] else if (!pedido.estado.enCurso)
                              const _Entregado(),
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
  const _Resumen({
    required this.pedido,
    required this.nombreCliente,
    required this.contactoCliente,
  });

  final Pedido pedido;
  final String nombreCliente;
  final String? contactoCliente;

  @override
  Widget build(BuildContext context) {
    final entregado = pedido.estado == EstadoPedido.entregado;
    return LavaTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Datos de la recolección', style: Tema.subtitulo())),
              Pildora(
                texto: pedido.estado.etiqueta,
                color: entregado ? Tema.verde : Tema.ambar,
                fondo: entregado ? Tema.verdeSuave : Tema.ambarSuave,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Dato(
            icono: Icons.person_rounded,
            titulo: 'Cliente',
            valor: contactoCliente == null ? nombreCliente : '$nombreCliente · $contactoCliente',
          ),
          _Dato(icono: Icons.location_on_rounded, titulo: 'Dirección', valor: pedido.direccion),
          _Dato(
            icono: Icons.event_rounded,
            titulo: 'Recolección',
            valor: formatoFechaHora(pedido.recoleccion),
          ),
          _Dato(
            icono: Icons.local_laundry_service_rounded,
            titulo: 'Servicio',
            valor: '${pedido.nombreServicio} · ${pedido.kilos} kg aprox.',
          ),
          if (pedido.notas != null)
            _Dato(icono: Icons.sticky_note_2_rounded, titulo: 'Notas', valor: pedido.notas!),
          _Dato(
            icono: Icons.payments_rounded,
            titulo: pedido.pesado ? 'Total según el peso real' : 'Total estimado',
            valor: pedido.pesado
                ? '${pedido.totalVigente.texto} (${formatoKilos(pedido.kilosReales!)} kg)'
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

/// Formulario: peso real de la ropa. Muestra el total que saldría con ese peso.
class _FormularioPeso extends StatelessWidget {
  const _FormularioPeso({
    required this.form,
    required this.controller,
    required this.pedido,
    required this.guardando,
    required this.error,
    required this.validar,
    required this.leerPeso,
    required this.onGuardar,
  });

  final GlobalKey<FormState> form;
  final TextEditingController controller;
  final Pedido pedido;
  final bool guardando;
  final String? error;
  final String? Function(String?) validar;
  final double? Function(String?) leerPeso;
  final VoidCallback onGuardar;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final servicio = app.catalogo.servicio(pedido.servicioId);

    return LavaTarjeta(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registrar peso', style: Tema.subtitulo()),
            const SizedBox(height: 4),
            Text(
              'Pesa la ropa al recogerla: el total final se calcula con este peso.',
              style: Tema.cuerpo(color: Tema.textoSuave, tamano: 13.5),
            ),
            const SizedBox(height: 16),
            LavaCampo(
              etiqueta: 'Peso real (kg)',
              controller: controller,
              hint: 'Ej. 4.5',
              icono: Icons.scale_rounded,
              teclado: const TextInputType.numberWithOptions(decimal: true),
              accion: TextInputAction.done,
              onEnviado: (_) => onGuardar(),
              validator: validar,
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, valor, _) {
                final kilos = leerPeso(valor.text);
                if (kilos == null ||
                    servicio == null ||
                    kilos < Pedido.pesoMinimo ||
                    kilos > Pedido.pesoMaximo) {
                  return const SizedBox.shrink();
                }
                final redondeado = (kilos * 10).round() / 10;
                final total = servicio.precioPorKilo.porKilos(redondeado);
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Tema.primarioSuave,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${formatoKilos(redondeado)} kg × ${servicio.precioPorKilo.texto}',
                          style: Tema.cuerpo(color: Tema.textoSuave, tamano: 14),
                        ),
                      ),
                      Text(
                        total.texto,
                        style: Tema.titulo(color: Tema.primario, tamano: 22),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (error != null) MensajeError(error!),
            FilledButton(
              onPressed: guardando ? null : onGuardar,
              child: guardando
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : Text(pedido.pesado ? 'Actualizar peso' : 'Guardar peso'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _Entregado extends StatelessWidget {
  const _Entregado();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Tema.verdeSuave,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Tema.verde),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este pedido ya se entregó.',
              style: Tema.subtitulo(color: Tema.verde, tamano: 16),
            ),
          ),
        ],
      ),
    );
  }
}
