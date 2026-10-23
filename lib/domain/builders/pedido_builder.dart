import '../../core/ids.dart';
import '../entities/pedido.dart';
import '../entities/servicio.dart';
import '../value_objects/dinero.dart';
import '../value_objects/estados.dart';

class DatosInvalidosException implements Exception {
  DatosInvalidosException(this.errores);

  final List<String> errores;

  @override
  String toString() => 'DatosInvalidosException: ${errores.join(' | ')}';
}

/// Patrón Builder: arma un Pedido paso a paso.
/// También funciona como "borrador": la pantalla de servicios llena el servicio
/// y los kilos, y la de Confirmar recolección completa dirección, fecha y notas.
/// Obligatorios: usuario, número, servicio, kilos, dirección y fecha de recolección.
class PedidoBuilder {
  static const int kilosMinimos = 1;
  static const int kilosMaximos = 10;
  static const int kilosPorDefecto = 3;

  String? _id;
  String? _usuarioId;
  int? _numero;
  Servicio? _servicio;
  int _kilos = kilosPorDefecto;
  DateTime? _fecha;
  String? _direccion;
  DateTime? _recoleccion;
  String? _notas;

  Servicio? get servicio => _servicio;
  int get kilos => _kilos;

  /// Precio aproximado: el final se confirma al pesar la ropa.
  Dinero? get totalEstimado {
    final s = _servicio;
    return s == null ? null : s.precioPorKilo * _kilos;
  }

  PedidoBuilder conId(String id) {
    _id = id;
    return this;
  }

  PedidoBuilder conUsuario(String usuarioId) {
    _usuarioId = usuarioId;
    return this;
  }

  PedidoBuilder conNumero(int numero) {
    _numero = numero;
    return this;
  }

  PedidoBuilder conServicio(Servicio servicio) {
    _servicio = servicio;
    return this;
  }

  /// Los kilos siempre quedan entre [kilosMinimos] y [kilosMaximos].
  PedidoBuilder conKilos(int kilos) {
    if (kilos < kilosMinimos) {
      _kilos = kilosMinimos;
    } else if (kilos > kilosMaximos) {
      _kilos = kilosMaximos;
    } else {
      _kilos = kilos;
    }
    return this;
  }

  PedidoBuilder conFecha(DateTime fecha) {
    _fecha = fecha;
    return this;
  }

  PedidoBuilder conDireccion(String direccion) {
    _direccion = direccion;
    return this;
  }

  PedidoBuilder conRecoleccion(DateTime recoleccion) {
    _recoleccion = recoleccion;
    return this;
  }

  PedidoBuilder conNotas(String? notas) {
    _notas = notas;
    return this;
  }

  /// Si se manda [ahora], también se revisa que la recolección sea a futuro.
  List<String> validar({DateTime? ahora}) {
    final errores = <String>[];
    if (_usuarioId == null || _usuarioId!.isEmpty) {
      errores.add('Falta la persona usuaria.');
    }
    if (_numero == null || _numero! <= 0) {
      errores.add('Falta el número de pedido.');
    }
    if (_servicio == null) {
      errores.add('Elige un servicio.');
    }
    if (_direccion == null || _direccion!.trim().length < 5) {
      errores.add('Escribe la dirección de recolección (calle, número y colonia).');
    }
    if (_recoleccion == null) {
      errores.add('Elige el día y la hora de recolección.');
    } else if (ahora != null && !_recoleccion!.isAfter(ahora)) {
      errores.add('La recolección debe ser en una fecha y hora que aún no pasan.');
    }
    return errores;
  }

  Pedido construir({DateTime? ahora}) {
    final errores = validar(ahora: ahora);
    if (errores.isNotEmpty) throw DatosInvalidosException(errores);

    final servicio = _servicio!;
    final notas = _notas?.trim();
    return Pedido(
      id: _id ?? generarId(),
      usuarioId: _usuarioId!,
      numero: _numero!,
      servicioId: servicio.id,
      nombreServicio: servicio.nombre,
      kilos: _kilos,
      total: servicio.precioPorKilo * _kilos,
      fecha: _fecha ?? ahora ?? DateTime.now(),
      direccion: _direccion!.trim(),
      recoleccion: _recoleccion!,
      estado: EstadoPedido.solicitado,
      notas: (notas == null || notas.isEmpty) ? null : notas,
    );
  }
}
