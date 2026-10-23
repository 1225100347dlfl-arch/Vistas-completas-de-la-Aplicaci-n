import 'package:flutter/material.dart';

import '../tema.dart';

/// Tarjeta blanca con esquinas muy redondeadas y sombra suave.
/// Si recibe [onTap] se puede tocar y muestra el efecto de ondas.
class LavaTarjeta extends StatelessWidget {
  const LavaTarjeta({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = Tema.tarjeta,
    this.bordeColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color? bordeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(24);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radio, boxShadow: Tema.sombraSuave),
      child: Material(
        color: color,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radio,
          side: BorderSide(color: bordeColor ?? Tema.borde),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Icono dentro de un círculo de color suave.
class IconoBurbuja extends StatelessWidget {
  const IconoBurbuja({
    super.key,
    required this.icono,
    this.color = Tema.primario,
    this.fondo = Tema.primarioSuave,
    this.tamano = 48,
  });

  final IconData icono;
  final Color color;
  final Color fondo;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
      child: Icon(icono, color: color, size: tamano * 0.5),
    );
  }
}

/// Etiqueta pequeña en forma de pastilla ("Tu favorito", "Lavado"...).
class Pildora extends StatelessWidget {
  const Pildora({
    super.key,
    required this.texto,
    this.icono,
    this.color = Tema.primario,
    this.fondo = Tema.primarioSuave,
  });

  final String texto;
  final IconData? icono;
  final Color color;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

/// Botón circular de "volver" (siempre a la izquierda, como en el prototipo).
class BotonAtras extends StatelessWidget {
  const BotonAtras({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Volver',
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(side: BorderSide(color: Tema.borde)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).maybePop(),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.arrow_back_rounded, color: Tema.texto),
          ),
        ),
      ),
    );
  }
}

/// Encabezado de las pantallas internas: botón de volver, título y,
/// si es parte de un proceso, "Paso X de Y" con barra de progreso.
class CabeceraPantalla extends StatelessWidget {
  const CabeceraPantalla({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.paso,
    this.totalPasos = 3,
  });

  final String titulo;
  final String? subtitulo;

  /// Si se manda, el subtítulo es "Paso X de Y" y se dibuja la barra de progreso.
  final int? paso;
  final int totalPasos;

  @override
  Widget build(BuildContext context) {
    final etiquetaSub = paso != null ? 'Paso $paso de $totalPasos' : subtitulo;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BotonAtras(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: Tema.titulo(tamano: 24)),
                    if (etiquetaSub != null) ...[
                      const SizedBox(height: 2),
                      Text(etiquetaSub, style: Tema.etiqueta()),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (paso != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: paso! / totalPasos,
                minHeight: 6,
                backgroundColor: Tema.borde,
                color: Tema.primario,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Campo de texto con su etiqueta arriba (siempre visible, no solo el hint).
class LavaCampo extends StatelessWidget {
  const LavaCampo({
    super.key,
    required this.etiqueta,
    required this.controller,
    this.hint,
    this.icono,
    this.obscuro = false,
    this.maxLineas = 1,
    this.validator,
    this.soloLectura = false,
    this.onTap,
    this.teclado,
    this.sufijo,
    this.accion,
    this.onEnviado,
  });

  final String etiqueta;
  final TextEditingController controller;
  final String? hint;
  final IconData? icono;
  final bool obscuro;
  final int maxLineas;
  final String? Function(String?)? validator;
  final bool soloLectura;
  final VoidCallback? onTap;
  final TextInputType? teclado;
  final Widget? sufijo;
  final TextInputAction? accion;
  final ValueChanged<String>? onEnviado;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder borde(Color color, [double ancho = 1.5]) => OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: color, width: ancho),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: Tema.cuerpo(tamano: 14).copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: obscuro,
            maxLines: maxLineas,
            validator: validator,
            readOnly: soloLectura,
            onTap: onTap,
            keyboardType: teclado,
            textInputAction: accion,
            onFieldSubmitted: onEnviado,
            style: Tema.cuerpo(tamano: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: Tema.cuerpo(tamano: 15, color: Tema.textoSuave.withAlpha(170)),
              prefixIcon: icono == null ? null : Icon(icono, size: 22, color: Tema.primario),
              suffixIcon: sufijo,
              filled: true,
              fillColor: const Color(0xFFF9FBFE),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              border: borde(Tema.borde),
              enabledBorder: borde(Tema.borde),
              focusedBorder: borde(Tema.primario, 2.2),
              errorBorder: borde(Tema.rojo),
              focusedErrorBorder: borde(Tema.rojo, 2.2),
              errorStyle: const TextStyle(
                fontSize: 13,
                color: Tema.rojo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mensaje de error visible (rojo suave con icono) para formularios.
class MensajeError extends StatelessWidget {
  const MensajeError(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Tema.rojoSuave,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Tema.rojo.withAlpha(90)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Tema.rojo, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: Tema.cuerpo(color: Tema.rojo, tamano: 14).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estrellas de solo lectura (calificación de un pedido).
class EstrellasMini extends StatelessWidget {
  const EstrellasMini({super.key, required this.valor, this.tamano = 18});

  final int valor;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$valor de 5 estrellas',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              i <= valor ? Icons.star_rounded : Icons.star_outline_rounded,
              size: tamano,
              color: i <= valor ? Tema.estrella : Tema.borde,
            ),
        ],
      ),
    );
  }
}
