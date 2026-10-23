import '../../domain/entities/servicio.dart';
import '../../domain/services/catalogo_service.dart';
import '../../domain/value_objects/dinero.dart';
import '../../domain/value_objects/estados.dart';

/// Patrón Adapter: traduce "dame los servicios" a "lee esta lista fija".
/// Para traerlos de un servidor se crea otro adaptador que implemente
/// [CatalogoService] y se cambia solo en main.dart.
///
/// Precios por kilo: con los 3 kg de ejemplo del prototipo dan $60 (solo lavado)
/// y $90 (lavado y planchado).
class CatalogoLocalAdapter implements CatalogoService {
  static const List<Servicio> _servicios = [
    Servicio(
      id: 'solo-lavado',
      tipo: TipoServicio.soloLavado,
      nombre: 'Solo lavado',
      descripcion: 'Lavamos y secamos tu ropa. Te la devolvemos doblada.',
      precioPorKilo: Dinero(20),
      incluye: ['Lavado', 'Secado'],
    ),
    Servicio(
      id: 'lavado-planchado',
      tipo: TipoServicio.lavadoYPlanchado,
      nombre: 'Lavado y planchado',
      descripcion: 'Todo lo anterior, más planchado para que la uses al instante.',
      precioPorKilo: Dinero(30),
      incluye: ['Lavado', 'Secado', 'Planchado'],
    ),
  ];

  @override
  List<Servicio> servicios() => _servicios;

  @override
  Servicio? servicio(String id) {
    for (final s in _servicios) {
      if (s.id == id) return s;
    }
    return null;
  }
}
