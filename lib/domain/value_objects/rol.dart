/// Los 3 tipos de usuario de LavaYa; cada uno tiene su propio dashboard.
enum RolUsuario { cliente, repartidor, admin }

extension RolUsuarioX on RolUsuario {
  String get etiqueta {
    switch (this) {
      case RolUsuario.cliente:
        return 'Cliente';
      case RolUsuario.repartidor:
        return 'Repartidor';
      case RolUsuario.admin:
        return 'Administrador';
    }
  }

  String get descripcion {
    switch (this) {
      case RolUsuario.cliente:
        return 'Pide la recolección de tu ropa';
      case RolUsuario.repartidor:
        return 'Recoge, pesa y entrega los pedidos';
      case RolUsuario.admin:
        return 'Asigna pedidos y ve a los usuarios';
    }
  }
}
