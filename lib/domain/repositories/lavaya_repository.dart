import '../entities/pedido.dart';
import '../entities/usuario.dart';
import '../value_objects/contacto.dart';

/// Patrón Repository: una sola puerta de acceso a los datos.
/// Las pantallas y la lógica no saben si vienen del celular o de internet.
abstract class LavaYaRepository {
  Future<void> inicializar();

  // Cuenta y sesión
  Usuario? usuarioPorContacto(Contacto contacto);
  Usuario? usuarioPorId(String id);
  List<Usuario> usuarios();
  Future<void> guardarUsuario(Usuario usuario);
  Usuario? usuarioEnSesion();
  Future<void> abrirSesion(String usuarioId);
  Future<void> cerrarSesion();

  // Pedidos
  List<Pedido> pedidosDe(String usuarioId);
  List<Pedido> todosLosPedidos();
  Pedido? pedido(String id);
  Future<void> guardarPedido(Pedido pedido);
}
