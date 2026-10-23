import '../value_objects/contacto.dart';
import '../value_objects/rol.dart';

class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.contacto,
    required this.contrasenaHash,
    this.rol = RolUsuario.cliente,
  });

  final String id;
  final String nombre;
  final Contacto contacto;
  final String contrasenaHash;
  final RolUsuario rol;
}
