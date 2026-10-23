import '../domain/entities/pedido.dart';
import '../domain/entities/usuario.dart';
import '../domain/value_objects/contacto.dart';
import '../domain/value_objects/dinero.dart';
import '../domain/value_objects/estados.dart';
import '../domain/value_objects/rol.dart';

/// Conversión entre entidades del dominio y mapas JSON para guardarlas.

Map<String, dynamic> usuarioAMapa(Usuario u) => {
      'id': u.id,
      'nombre': u.nombre,
      'contactoTipo': u.contacto.tipo.name,
      'contactoValor': u.contacto.valor,
      'contrasenaHash': u.contrasenaHash,
      'rol': u.rol.name,
    };

Usuario usuarioDeMapa(Map<String, dynamic> m) => Usuario(
      id: m['id'] as String,
      nombre: m['nombre'] as String,
      contacto: Contacto.deGuardado(
        m['contactoTipo'] as String,
        m['contactoValor'] as String,
      ),
      contrasenaHash: m['contrasenaHash'] as String,
      rol: RolUsuario.values.byName(m['rol'] as String),
    );

Map<String, dynamic> pedidoAMapa(Pedido p) => {
      'id': p.id,
      'usuarioId': p.usuarioId,
      'numero': p.numero,
      'servicioId': p.servicioId,
      'nombreServicio': p.nombreServicio,
      'kilos': p.kilos,
      'total': p.total.pesos,
      'fecha': p.fecha.toIso8601String(),
      'direccion': p.direccion,
      'recoleccion': p.recoleccion.toIso8601String(),
      'estado': p.estado.name,
      'notas': p.notas,
      'calificacion': p.calificacion,
      'comentario': p.comentario,
      'repartidorId': p.repartidorId,
      'kilosReales': p.kilosReales,
      'totalFinal': p.totalFinal?.pesos,
    };

Pedido pedidoDeMapa(Map<String, dynamic> m) => Pedido(
      id: m['id'] as String,
      usuarioId: m['usuarioId'] as String,
      numero: m['numero'] as int,
      servicioId: m['servicioId'] as String,
      nombreServicio: m['nombreServicio'] as String,
      kilos: m['kilos'] as int,
      total: Dinero(m['total'] as int),
      fecha: DateTime.parse(m['fecha'] as String),
      direccion: m['direccion'] as String,
      recoleccion: DateTime.parse(m['recoleccion'] as String),
      estado: EstadoPedido.values.byName(m['estado'] as String),
      notas: m['notas'] as String?,
      calificacion: m['calificacion'] as int?,
      comentario: m['comentario'] as String?,
      repartidorId: m['repartidorId'] as String?,
      kilosReales: (m['kilosReales'] as num?)?.toDouble(),
      totalFinal: m['totalFinal'] == null ? null : Dinero(m['totalFinal'] as int),
    );
