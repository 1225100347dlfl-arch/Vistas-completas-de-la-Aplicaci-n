/// Tipos de servicio que ofrece la lavandería.
enum TipoServicio { soloLavado, lavadoYPlanchado }

/// Etapas de un pedido (las mismas que muestra la pantalla de seguimiento).
enum EstadoPedido { solicitado, recogido, enProceso, enCamino, entregado }

extension EstadoPedidoX on EstadoPedido {
  String get etiqueta {
    switch (this) {
      case EstadoPedido.solicitado:
        return 'Solicitado';
      case EstadoPedido.recogido:
        return 'Recogido';
      case EstadoPedido.enProceso:
        return 'En proceso';
      case EstadoPedido.enCamino:
        return 'En camino';
      case EstadoPedido.entregado:
        return 'Entregado';
    }
  }

  /// Siguiente etapa; null si ya se entregó.
  EstadoPedido? get siguiente {
    final i = EstadoPedido.values.indexOf(this);
    return i + 1 < EstadoPedido.values.length ? EstadoPedido.values[i + 1] : null;
  }

  bool get enCurso => this != EstadoPedido.entregado;

  /// Tiempo estimado que se le muestra a la persona (valores de ejemplo).
  int get minutosRestantes {
    switch (this) {
      case EstadoPedido.solicitado:
        return 60;
      case EstadoPedido.recogido:
        return 45;
      case EstadoPedido.enProceso:
        return 30;
      case EstadoPedido.enCamino:
        return 12;
      case EstadoPedido.entregado:
        return 0;
    }
  }
}
