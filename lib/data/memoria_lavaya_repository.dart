import '../domain/entities/pedido.dart';
import '../domain/entities/usuario.dart';
import '../domain/repositories/lavaya_repository.dart';
import '../domain/value_objects/contacto.dart';
import 'mappers.dart';

/// Implementación en memoria. También sirve para pruebas (no toca el disco).
/// Las lecturas son síncronas (caché en memoria); las escrituras llaman a [persistir].
class MemoriaLavaYaRepository implements LavaYaRepository {
  final Map<String, Usuario> _usuarios = {};
  final Map<String, Pedido> _pedidos = {};
  String? _sesionUsuarioId;

  /// Gancho para que las subclases guarden los cambios. Aquí no hace nada.
  Future<void> persistir() async {}

  @override
  Future<void> inicializar() async {}

  // ---------------- Cuenta y sesión ----------------
  @override
  Usuario? usuarioPorContacto(Contacto contacto) {
    for (final u in _usuarios.values) {
      if (u.contacto == contacto) return u;
    }
    return null;
  }

  @override
  Usuario? usuarioPorId(String id) => _usuarios[id];

  @override
  List<Usuario> usuarios() => _usuarios.values.toList();

  @override
  Future<void> guardarUsuario(Usuario usuario) async {
    _usuarios[usuario.id] = usuario;
    await persistir();
  }

  @override
  Usuario? usuarioEnSesion() {
    final id = _sesionUsuarioId;
    return id == null ? null : _usuarios[id];
  }

  @override
  Future<void> abrirSesion(String usuarioId) async {
    _sesionUsuarioId = usuarioId;
    await persistir();
  }

  @override
  Future<void> cerrarSesion() async {
    _sesionUsuarioId = null;
    await persistir();
  }

  // ---------------- Pedidos ----------------
  @override
  List<Pedido> pedidosDe(String usuarioId) =>
      _pedidos.values.where((p) => p.usuarioId == usuarioId).toList();

  @override
  List<Pedido> todosLosPedidos() => _pedidos.values.toList();

  @override
  Pedido? pedido(String id) => _pedidos[id];

  @override
  Future<void> guardarPedido(Pedido pedido) async {
    _pedidos[pedido.id] = pedido;
    await persistir();
  }

  // ---------------- JSON ----------------
  Map<String, dynamic> aJson() => {
        'usuarios': _usuarios.values.map(usuarioAMapa).toList(),
        'pedidos': _pedidos.values.map(pedidoAMapa).toList(),
        'sesion': _sesionUsuarioId,
      };

  void cargarDesdeJson(Map<String, dynamic> json) {
    final usuarios = (json['usuarios'] as List<dynamic>?) ?? const <dynamic>[];
    for (final item in usuarios) {
      final u = usuarioDeMapa(Map<String, dynamic>.from(item as Map));
      _usuarios[u.id] = u;
    }
    final pedidos = (json['pedidos'] as List<dynamic>?) ?? const <dynamic>[];
    for (final item in pedidos) {
      final p = pedidoDeMapa(Map<String, dynamic>.from(item as Map));
      _pedidos[p.id] = p;
    }
    _sesionUsuarioId = json['sesion'] as String?;
  }
}
