import 'package:flutter/material.dart';

import '../../domain/value_objects/estados.dart';
import '../tema.dart';

/// Cuánto del camino ha recorrido el repartidor según la etapa del pedido.
/// Antes de salir está en la lavandería (0) y al entregar llega a la casa (1).
double progresoDeRecorrido(EstadoPedido estado) {
  switch (estado) {
    case EstadoPedido.solicitado:
    case EstadoPedido.recogido:
    case EstadoPedido.enProceso:
      return 0;
    case EstadoPedido.enCamino:
      return 0.7;
    case EstadoPedido.entregado:
      return 1;
  }
}

/// Mapa dibujado en la propia app (sin Google Maps ni claves): calles, un parque,
/// la ruta y la posición del repartidor. El repartidor se mueve con una animación
/// cuando cambia la etapa.
class MapaSeguimiento extends StatelessWidget {
  const MapaSeguimiento({super.key, required this.estado});

  final EstadoPedido estado;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mapa de seguimiento. Estado del pedido: ${estado.etiqueta}',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progresoDeRecorrido(estado)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        builder: (context, progreso, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _MapaPainter(progreso: progreso, estado: estado),
          );
        },
      ),
    );
  }
}

class _MapaPainter extends CustomPainter {
  _MapaPainter({required this.progreso, required this.estado});

  final double progreso;
  final EstadoPedido estado;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fondo y parque
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE6ECF4));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.67, h * 0.06, w * 0.27, h * 0.36),
        const Radius.circular(18),
      ),
      Paint()..color = const Color(0xFFCDE7CF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.02, h * 0.58, w * 0.25, h * 0.14),
        const Radius.circular(14),
      ),
      Paint()..color = const Color(0xFFD6E4F2),
    );

    // Calles
    final calle = Paint()
      ..color = Colors.white
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    for (final x in [0.15, 0.40, 0.62, 0.86]) {
      canvas.drawLine(Offset(w * x, 0), Offset(w * x, h), calle);
    }
    for (final y in [0.20, 0.50, 0.80]) {
      canvas.drawLine(Offset(0, h * y), Offset(w, h * y), calle);
    }

    // Ruta: lavandería -> tu casa, siguiendo las calles
    final puntos = <Offset>[
      Offset(w * 0.15, h * 0.80),
      Offset(w * 0.15, h * 0.50),
      Offset(w * 0.62, h * 0.50),
      Offset(w * 0.62, h * 0.20),
    ];
    final largos = <double>[];
    var total = 0.0;
    for (var i = 0; i < puntos.length - 1; i++) {
      final d = (puntos[i + 1] - puntos[i]).distance;
      largos.add(d);
      total += d;
    }

    final rutaCompleta = Path()..moveTo(puntos[0].dx, puntos[0].dy);
    for (final p in puntos.skip(1)) {
      rutaCompleta.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      rutaCompleta,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Tema.primario.withAlpha(70)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Parte ya recorrida
    final recorrida = Path()..moveTo(puntos[0].dx, puntos[0].dy);
    var restante = progreso.clamp(0.0, 1.0).toDouble() * total;
    var posicion = puntos[0];
    for (var i = 0; i < largos.length; i++) {
      if (restante <= 0) break;
      final f = restante >= largos[i] ? 1.0 : restante / largos[i];
      posicion = puntos[i] + (puntos[i + 1] - puntos[i]) * f;
      recorrida.lineTo(posicion.dx, posicion.dy);
      restante -= largos[i];
    }
    canvas.drawPath(
      recorrida,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Tema.primario
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Tu casa
    final casa = puntos.last;
    final entregado = estado == EstadoPedido.entregado;
    final colorCasa = entregado ? Tema.verde : Tema.rojo;
    canvas.drawCircle(casa, 13, Paint()..color = Colors.white);
    canvas.drawCircle(casa, 9, Paint()..color = colorCasa);
    canvas.drawCircle(casa, 3.5, Paint()..color = Colors.white);
    _etiqueta(canvas, 'Tu casa', casa + const Offset(0, -30), colorCasa);

    // Repartidor (o la lavandería, mientras la ropa no sale)
    final enRuta = estado == EstadoPedido.enCamino || entregado;
    canvas.drawCircle(posicion, 14, Paint()..color = Colors.white);
    canvas.drawCircle(posicion, 10, Paint()..color = Tema.primario);
    canvas.drawCircle(posicion, 4, Paint()..color = Colors.white);
    _etiqueta(
      canvas,
      enRuta ? 'Repartidor' : 'LavaYa',
      posicion + const Offset(0, 30),
      Tema.primario,
    );
  }

  void _etiqueta(Canvas canvas, String texto, Offset centro, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: texto,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final caja = RRect.fromRectAndRadius(
      Rect.fromCenter(center: centro, width: tp.width + 18, height: tp.height + 10),
      const Radius.circular(11),
    );
    canvas.drawRRect(caja.shift(const Offset(0, 1.5)), Paint()..color = const Color(0x26000000));
    canvas.drawRRect(caja, Paint()..color = Colors.white);
    tp.paint(canvas, Offset(centro.dx - tp.width / 2, centro.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_MapaPainter anterior) =>
      anterior.progreso != progreso || anterior.estado != estado;
}
