import '../value_objects/dinero.dart';
import '../value_objects/estados.dart';

/// Un pedido de recolección. Guarda el nombre del servicio y el total tal como
/// eran al pedir, así el historial no cambia si luego cambian los precios.
class Pedido {
  const Pedido({
    required this.id,
    required this.usuarioId,
    required this.numero,
    required this.servicioId,
    required this.nombreServicio,
    required this.kilos,
    required this.total,
    required this.fecha,
    required this.direccion,
    required this.recoleccion,
    required this.estado,
    this.notas,
    this.calificacion,
    this.comentario,
    this.repartidorId,
    this.kilosReales,
    this.totalFinal,
  });

  /// Límites del peso real que registra el repartidor.
  static const double pesoMinimo = 0.5;
  static const double pesoMaximo = 30;

  final String id;

  /// El cliente que hizo el pedido.
  final String usuarioId;

  /// Número que ve la persona ("Pedido #128").
  final int numero;
  final String servicioId;
  final String nombreServicio;

  /// Kilos aproximados que dijo el cliente.
  final int kilos;

  /// Total estimado al pedir.
  final Dinero total;

  /// Cuándo se hizo el pedido.
  final DateTime fecha;
  final String direccion;

  /// Día y hora en que pasan por la ropa.
  final DateTime recoleccion;
  final EstadoPedido estado;
  final String? notas;

  /// De 1 a 5 estrellas; null si todavía no se califica.
  final int? calificacion;
  final String? comentario;

  /// Quién lo atiende; null mientras el administrador no lo asigna.
  final String? repartidorId;

  /// Peso que registró el repartidor al pesar la ropa, y el total que sale de él.
  final double? kilosReales;
  final Dinero? totalFinal;

  bool get calificado => calificacion != null;
  bool get asignado => repartidorId != null;
  bool get pesado => kilosReales != null;

  /// El total que corresponde mostrar: el real si ya se pesó, si no el estimado.
  Dinero get totalVigente => totalFinal ?? total;

  Pedido copiarCon({
    EstadoPedido? estado,
    int? calificacion,
    String? comentario,
    String? repartidorId,
    double? kilosReales,
    Dinero? totalFinal,
  }) {
    return Pedido(
      id: id,
      usuarioId: usuarioId,
      numero: numero,
      servicioId: servicioId,
      nombreServicio: nombreServicio,
      kilos: kilos,
      total: total,
      fecha: fecha,
      direccion: direccion,
      recoleccion: recoleccion,
      estado: estado ?? this.estado,
      notas: notas,
      calificacion: calificacion ?? this.calificacion,
      comentario: comentario ?? this.comentario,
      repartidorId: repartidorId ?? this.repartidorId,
      kilosReales: kilosReales ?? this.kilosReales,
      totalFinal: totalFinal ?? this.totalFinal,
    );
  }
}
