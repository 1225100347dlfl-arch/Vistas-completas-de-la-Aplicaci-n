import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/value_objects/estados.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';

const List<String> _palabras = ['Muy malo', 'Malo', 'Regular', 'Bueno', 'Excelente'];

/// 6. "Calificación": estrellas y comentario opcional de un pedido entregado.
/// Recibe como argumento de la ruta el id del pedido.
class CalificacionScreen extends StatefulWidget {
  const CalificacionScreen({super.key});

  @override
  State<CalificacionScreen> createState() => _CalificacionScreenState();
}

class _CalificacionScreenState extends State<CalificacionScreen> {
  final _comentario = TextEditingController();
  int _estrellas = 0;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviar(String pedidoId) async {
    final app = AppScope.leer(context);
    final nav = Navigator.of(context);
    final mensajes = ScaffoldMessenger.of(context);
    setState(() {
      _enviando = true;
      _error = null;
    });
    final error = await app.calificar(pedidoId, _estrellas, _comentario.text);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _enviando = false;
        _error = error;
      });
      return;
    }
    nav.pop();
    mensajes
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('¡Gracias por tu opinión!')));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final id = ModalRoute.of(context)?.settings.arguments;
    final pedido = id is String ? app.pedido(id) : null;
    final puedeCalificar =
        pedido != null && pedido.estado == EstadoPedido.entregado && !pedido.calificado;

    return Scaffold(
      backgroundColor: Tema.fondo,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                CabeceraPantalla(
                  titulo: 'Calificar servicio',
                  subtitulo: pedido == null ? null : 'Pedido #${pedido.numero}',
                ),
                Expanded(
                  child: (pedido == null || !puedeCalificar)
                      ? _NoSePuede(pedidoExiste: pedido != null)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                          child: Column(
                            children: [
                              LavaTarjeta(
                                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                                child: Column(
                                  children: [
                                    const IconoBurbuja(
                                      icono: Icons.local_laundry_service_rounded,
                                      tamano: 64,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '¿Cómo estuvo tu servicio?',
                                      textAlign: TextAlign.center,
                                      style: Tema.titulo(tamano: 22),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Pedido #${pedido.numero} · ${pedido.nombreServicio} · Entregado',
                                      textAlign: TextAlign.center,
                                      style: Tema.cuerpo(color: Tema.textoSuave, tamano: 14),
                                    ),
                                    const SizedBox(height: 22),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        for (var i = 1; i <= 5; i++)
                                          _Estrella(
                                            numero: i,
                                            activa: i <= _estrellas,
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              setState(() => _estrellas = i);
                                            },
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _estrellas == 0
                                          ? 'Toca una estrella'
                                          : '$_estrellas de 5 estrellas · ${_palabras[_estrellas - 1]}',
                                      style: Tema.subtitulo(
                                        color: _estrellas == 0 ? Tema.textoSuave : Tema.primario,
                                        tamano: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              LavaTarjeta(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
                                child: LavaCampo(
                                  etiqueta: 'Comentario (opcional)',
                                  controller: _comentario,
                                  hint: 'Cuéntanos tu experiencia...',
                                  maxLineas: 4,
                                  teclado: TextInputType.multiline,
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (_error != null) MensajeError(_error!),
                              FilledButton(
                                onPressed: (_estrellas == 0 || _enviando)
                                    ? null
                                    : () => _enviar(pedido.id),
                                child: _enviando
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 3),
                                      )
                                    : const Text('Enviar'),
                              ),
                            ],
                          ),
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

/// Una estrella grande y tocable; crece un poco al activarse.
class _Estrella extends StatelessWidget {
  const _Estrella({required this.numero, required this.activa, required this.onTap});

  final int numero;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: activa,
      label: 'Calificar con $numero ${numero == 1 ? 'estrella' : 'estrellas'}',
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedScale(
            scale: activa ? 1.12 : 1,
            duration: const Duration(milliseconds: 160),
            child: Icon(
              activa ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 46,
              color: activa ? Tema.estrella : Tema.borde,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoSePuede extends StatelessWidget {
  const _NoSePuede({required this.pedidoExiste});

  final bool pedidoExiste;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          pedidoExiste
              ? 'Este pedido ya se calificó o todavía no se entrega.'
              : 'No encontramos ese pedido.',
          textAlign: TextAlign.center,
          style: Tema.cuerpo(color: Tema.textoSuave, tamano: 16),
        ),
      ),
    );
  }
}
