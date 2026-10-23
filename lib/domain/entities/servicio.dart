import '../value_objects/dinero.dart';
import '../value_objects/estados.dart';

/// Un servicio del catálogo (por ejemplo "Solo lavado").
class Servicio {
  const Servicio({
    required this.id,
    required this.tipo,
    required this.nombre,
    required this.descripcion,
    required this.precioPorKilo,
    this.incluye = const <String>[],
  });

  final String id;
  final TipoServicio tipo;
  final String nombre;
  final String descripcion;
  final Dinero precioPorKilo;

  /// Etapas que incluye ("Lavado", "Secado", "Planchado"...).
  final List<String> incluye;
}
