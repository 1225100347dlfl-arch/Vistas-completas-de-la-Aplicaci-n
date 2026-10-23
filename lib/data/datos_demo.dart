import '../core/seguridad.dart';
import '../domain/entities/pedido.dart';
import '../domain/entities/usuario.dart';
import '../domain/repositories/lavaya_repository.dart';
import '../domain/value_objects/contacto.dart';
import '../domain/value_objects/dinero.dart';
import '../domain/value_objects/estados.dart';
import '../domain/value_objects/rol.dart';

/// Cuentas de ejemplo, una por tipo de usuario, para probar sin registrarte.
/// Todas usan la misma contraseña.
const String contrasenaDemo = 'lavaya123';
const String correoDemo = 'diana@lavaya.app'; // Cliente
const String correoRepartidorDemo = 'repartidor@lavaya.app'; // Repartidor
const String correoAdminDemo = 'admin@lavaya.app'; // Administrador

const String _idDiana = 'demo-diana';
const String _idMariana = 'demo-mariana';
const String _idCarlos = 'demo-carlos';
const String _idAdmin = 'demo-admin';

Future<void> _usuarioDemo(
  LavaYaRepository repo, {
  required String id,
  required String nombre,
  required String correo,
  required RolUsuario rol,
}) async {
  final contacto = Contacto.tryParse(correo)!;
  if (repo.usuarioPorContacto(contacto) != null) return;
  await repo.guardarUsuario(
    Usuario(
      id: id,
      nombre: nombre,
      contacto: contacto,
      contrasenaHash: hashContrasena(contrasenaDemo),
      rol: rol,
    ),
  );
}

/// Crea los datos de ejemplo la primera vez (y solo lo que falte):
///  - Diana (cliente) con los 3 pedidos del historial del prototipo.
///  - Mariana (cliente) con 2 pedidos en curso, uno todavía sin repartidor.
///  - Carlos (repartidor) con 4 pedidos asignados.
///  - Sofía (administradora).
/// Así las listas, los dashboards y los formularios tienen datos desde el inicio.
Future<void> sembrarDatosDemo(LavaYaRepository repo) async {
  await _usuarioDemo(repo, id: _idDiana, nombre: 'Diana', correo: correoDemo, rol: RolUsuario.cliente);
  await _usuarioDemo(repo, id: _idMariana, nombre: 'Mariana', correo: 'mariana@lavaya.app', rol: RolUsuario.cliente);
  await _usuarioDemo(repo, id: _idCarlos, nombre: 'Carlos', correo: correoRepartidorDemo, rol: RolUsuario.repartidor);
  await _usuarioDemo(repo, id: _idAdmin, nombre: 'Sofía', correo: correoAdminDemo, rol: RolUsuario.admin);

  const direccionDiana = 'Calle Hidalgo 45, Col. Centro';
  final demo = <Pedido>[
    Pedido(
      id: 'demo-128',
      usuarioId: _idDiana,
      numero: 128,
      servicioId: 'lavado-planchado',
      nombreServicio: 'Lavado y planchado',
      kilos: 3,
      total: const Dinero(90),
      fecha: DateTime(2026, 10, 3),
      direccion: direccionDiana,
      recoleccion: DateTime(2026, 10, 3, 10, 0),
      estado: EstadoPedido.entregado,
      notas: 'Portón negro',
      repartidorId: _idCarlos,
    ),
    Pedido(
      id: 'demo-124',
      usuarioId: _idDiana,
      numero: 124,
      servicioId: 'solo-lavado',
      nombreServicio: 'Solo lavado',
      kilos: 3,
      total: const Dinero(60),
      fecha: DateTime(2026, 9, 28),
      direccion: direccionDiana,
      recoleccion: DateTime(2026, 9, 28, 17, 30),
      estado: EstadoPedido.entregado,
      calificacion: 4,
      repartidorId: _idCarlos,
    ),
    Pedido(
      id: 'demo-119',
      usuarioId: _idDiana,
      numero: 119,
      servicioId: 'solo-lavado',
      nombreServicio: 'Solo lavado',
      kilos: 3,
      total: const Dinero(60),
      fecha: DateTime(2026, 9, 21),
      direccion: direccionDiana,
      recoleccion: DateTime(2026, 9, 21, 9, 0),
      estado: EstadoPedido.entregado,
      calificacion: 5,
      repartidorId: _idCarlos,
    ),
    Pedido(
      id: 'demo-129',
      usuarioId: _idMariana,
      numero: 129,
      servicioId: 'solo-lavado',
      nombreServicio: 'Solo lavado',
      kilos: 4,
      total: const Dinero(80),
      fecha: DateTime(2026, 10, 18),
      direccion: 'Av. Zacatecas 120, Col. Del Valle',
      recoleccion: DateTime(2026, 10, 20, 10, 0),
      estado: EstadoPedido.solicitado,
    ),
    Pedido(
      id: 'demo-130',
      usuarioId: _idMariana,
      numero: 130,
      servicioId: 'lavado-planchado',
      nombreServicio: 'Lavado y planchado',
      kilos: 5,
      total: const Dinero(150),
      fecha: DateTime(2026, 10, 17),
      direccion: 'Calle Morelos 18, Col. Las Flores',
      recoleccion: DateTime(2026, 10, 19, 17, 0),
      estado: EstadoPedido.recogido,
      notas: 'Llamar al llegar',
      repartidorId: _idCarlos,
    ),
  ];
  for (final p in demo) {
    if (repo.pedido(p.id) == null) await repo.guardarPedido(p);
  }
}
