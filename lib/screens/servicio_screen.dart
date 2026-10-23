import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/builders/pedido_builder.dart';
import '../domain/entities/servicio.dart';
import '../domain/value_objects/dinero.dart';
import '../domain/value_objects/estados.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import 'rutas.dart';

IconData _iconoDe(TipoServicio tipo) {
  switch (tipo) {
    case TipoServicio.soloLavado:
      return Icons.local_laundry_service_rounded;
    case TipoServicio.lavadoYPlanchado:
      return Icons.dry_cleaning_rounded;
  }
}

/// Paso 1 de 3: elegir el servicio y calcular el precio aproximado.
/// Todo el precio se ve antes de continuar y cambia al instante.
class ServicioScreen extends StatelessWidget {
  const ServicioScreen({super.key});

  void _continuar(BuildContext context) {
    if (AppScope.leer(context).servicioElegido == null) return;
    Navigator.of(context).pushNamed(rutaConfirmar);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final elegido = app.servicioElegido;
    final favorito = app.servicioFavorito;

    return Scaffold(
      backgroundColor: Tema.fondo,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const CabeceraPantalla(titulo: 'Elige tu servicio', paso: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  for (final s in app.servicios)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ServicioTarjeta(
                        servicio: s,
                        seleccionado: elegido?.id == s.id,
                        esFavorito: favorito?.id == s.id,
                        onTap: () => app.elegirServicio(s),
                      ),
                    ),
                  const SizedBox(height: 4),
                  _SelectorPeso(kilos: app.kilos, onCambio: app.cambiarKilos),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BarraInferior(
        estimado: app.estimado,
        habilitado: elegido != null,
        onContinuar: () => _continuar(context),
      ),
    );
  }
}

class _ServicioTarjeta extends StatelessWidget {
  const _ServicioTarjeta({
    required this.servicio,
    required this.seleccionado,
    required this.esFavorito,
    required this.onTap,
  });

  final Servicio servicio;
  final bool seleccionado;
  final bool esFavorito;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(24);
    return Semantics(
      button: true,
      selected: seleccionado,
      label: '${servicio.nombre}, ${servicio.precioPorKilo.texto} por kilo',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: seleccionado ? Tema.primarioSuave : Tema.tarjeta,
          borderRadius: radio,
          border: Border.all(
            color: seleccionado ? Tema.primario : Tema.borde,
            width: seleccionado ? 2 : 1.2,
          ),
          boxShadow: seleccionado ? Tema.sombraSuave : const <BoxShadow>[],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radio,
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconoBurbuja(
                        icono: _iconoDe(servicio.tipo),
                        fondo: seleccionado ? Colors.white : Tema.primarioSuave,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(servicio.nombre, style: Tema.subtitulo(tamano: 18)),
                                if (esFavorito)
                                  const Pildora(
                                    texto: 'Tu favorito',
                                    icono: Icons.favorite_rounded,
                                    color: Tema.ambar,
                                    fondo: Tema.ambarSuave,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              servicio.descripcion,
                              style: Tema.cuerpo(color: Tema.textoSuave, tamano: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _Indicador(activo: seleccionado),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final etapa in servicio.incluye)
                              Pildora(
                                texto: etapa,
                                icono: Icons.check_rounded,
                                color: Tema.verde,
                                fondo: Tema.verdeSuave,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            servicio.precioPorKilo.texto,
                            style: Tema.titulo(color: Tema.primario, tamano: 24),
                          ),
                          Text('por kilo', style: Tema.etiqueta()),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Círculo que se llena con una palomita cuando el servicio está elegido.
class _Indicador extends StatelessWidget {
  const _Indicador({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: activo ? Tema.primario : Colors.transparent,
        border: Border.all(color: activo ? Tema.primario : Tema.borde, width: 2),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: activo ? 1 : 0,
        child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
      ),
    );
  }
}

/// "¿Cuánta ropa?": botones grandes − / + para calcular el precio aproximado.
class _SelectorPeso extends StatelessWidget {
  const _SelectorPeso({required this.kilos, required this.onCambio});

  final int kilos;
  final ValueChanged<int> onCambio;

  @override
  Widget build(BuildContext context) {
    return LavaTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconoBurbuja(icono: Icons.shopping_bag_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿Cuánta ropa?', style: Tema.subtitulo()),
                    const SizedBox(height: 2),
                    Text(
                      'Es un cálculo aproximado; el precio final sale al pesar tu ropa.',
                      style: Tema.cuerpo(color: Tema.textoSuave, tamano: 13.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Tema.primarioSuave,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _BotonRedondo(
                  icono: Icons.remove_rounded,
                  etiqueta: 'Menos kilos',
                  onTap: kilos > PedidoBuilder.kilosMinimos ? () => onCambio(kilos - 1) : null,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animacion) => ScaleTransition(
                    scale: animacion,
                    child: FadeTransition(opacity: animacion, child: child),
                  ),
                  child: Text(
                    '$kilos kg',
                    key: ValueKey<int>(kilos),
                    style: Tema.titulo(tamano: 28),
                  ),
                ),
                _BotonRedondo(
                  icono: Icons.add_rounded,
                  etiqueta: 'Más kilos',
                  onTap: kilos < PedidoBuilder.kilosMaximos ? () => onCambio(kilos + 1) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({required this.icono, required this.etiqueta, required this.onTap});

  final IconData icono;
  final String etiqueta;

  /// Si es null el botón se ve apagado (se llegó al límite).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final activo = onTap != null;
    return Semantics(
      button: true,
      enabled: activo,
      label: etiqueta,
      child: Material(
        color: activo ? Colors.white : Colors.white.withAlpha(120),
        shape: const CircleBorder(),
        elevation: activo ? 1 : 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icono, color: activo ? Tema.primario : Tema.borde, size: 26),
          ),
        ),
      ),
    );
  }
}

/// Barra fija abajo: el precio siempre a la vista y el botón para seguir.
class _BarraInferior extends StatelessWidget {
  const _BarraInferior({
    required this.estimado,
    required this.habilitado,
    required this.onContinuar,
  });

  final Dinero? estimado;
  final bool habilitado;
  final VoidCallback onContinuar;

  @override
  Widget build(BuildContext context) {
    final e = estimado;
    final precio = e == null ? '—' : '${e.texto} aprox.';
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Color(0x1A1B3A6B), blurRadius: 24, offset: Offset(0, -6)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Precio estimado', style: Tema.etiqueta()),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      precio,
                      key: ValueKey<String>(precio),
                      style: Tema.titulo(color: Tema.primario, tamano: 26),
                    ),
                  ),
                  Text(
                    'Se confirma al pesar la ropa',
                    style: Tema.cuerpo(color: Tema.textoSuave, tamano: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: habilitado ? onContinuar : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 56),
                padding: const EdgeInsets.symmetric(horizontal: 26),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Continuar'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
