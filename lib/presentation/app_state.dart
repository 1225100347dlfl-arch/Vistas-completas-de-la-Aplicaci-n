import 'package:flutter/foundation.dart';

import '../core/ids.dart';
import '../core/reloj.dart';
import '../core/seguridad.dart';
import '../domain/builders/pedido_builder.dart';
import '../domain/entities/pedido.dart';
import '../domain/entities/servicio.dart';
import '../domain/entities/usuario.dart';
import '../domain/repositories/lavaya_repository.dart';
import '../domain/services/catalogo_service.dart';
import '../domain/value_objects/contacto.dart';
import '../domain/value_objects/dinero.dart';
import '../domain/value_objects/estados.dart';
import '../domain/value_objects/rol.dart';

/// Patrón Observer: es un ChangeNotifier. Cuando algo cambia (se inicia sesión,
/// se elige un servicio, avanza un pedido, se asigna un repartidor) avisa a las
/// pantallas interesadas y se actualizan solas.
///
/// También recibe sus dependencias por el constructor (inyección de dependencias),
/// por eso se puede probar con un repositorio en memoria.
///
/// Los datos viven en el repositorio (se guardan en el celular), así que el rol,
/// los pedidos y las listas se conservan al navegar y al cerrar la app.
class AppState extends ChangeNotifier {
  AppState({
    required this.repo,
    required this.catalogo,
    Reloj? reloj,
  }) : _reloj = reloj ?? relojSistema;

  final LavaYaRepository repo;
  final CatalogoService catalogo;
  final Reloj _reloj;

  Usuario? _usuario;

  /// Borrador del pedido que se está armando (patrón Builder).
  PedidoBuilder _borrador = PedidoBuilder();

  DateTime get ahora => _reloj();
  Usuario? get usuario => _usuario;
  bool get haySesion => _usuario != null;
  RolUsuario? get rol => _usuario?.rol;

  // ---------------- Arranque y sesión ----------------

  /// Carga los datos guardados y recupera la sesión si la había.
  Future<void> iniciar() async {
    await repo.inicializar();
    _usuario = repo.usuarioEnSesion();
    notifyListeners();
  }

  /// Devuelve el mensaje de error, o null si todo salió bien.
  Future<String?> iniciarSesion(String contacto, String contrasena) async {
    final c = Contacto.tryParse(contacto);
    if (c == null) return 'Escribe un correo o un teléfono de 10 dígitos.';
    if (contrasena.isEmpty) return 'Escribe tu contraseña.';
    final u = repo.usuarioPorContacto(c);
    if (u == null || u.contrasenaHash != hashContrasena(contrasena)) {
      return 'Correo, teléfono o contraseña incorrectos.';
    }
    await repo.abrirSesion(u.id);
    _usuario = u;
    _borrador = _nuevoBorrador();
    notifyListeners();
    return null;
  }

  /// Devuelve el mensaje de error, o null si salió bien (y ya deja la sesión abierta).
  Future<String?> registrar({
    required String nombre,
    required String contacto,
    required String contrasena,
    RolUsuario rol = RolUsuario.cliente,
  }) async {
    final n = nombre.trim();
    if (n.isEmpty) return 'Escribe tu nombre.';
    final c = Contacto.tryParse(contacto);
    if (c == null) return 'Escribe un correo o un teléfono de 10 dígitos.';
    if (contrasena.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
    if (repo.usuarioPorContacto(c) != null) return 'Ese correo o teléfono ya está registrado.';

    final u = Usuario(
      id: generarId(),
      nombre: n,
      contacto: c,
      contrasenaHash: hashContrasena(contrasena),
      rol: rol,
    );
    await repo.guardarUsuario(u);
    await repo.abrirSesion(u.id);
    _usuario = u;
    _borrador = _nuevoBorrador();
    notifyListeners();
    return null;
  }

  Future<void> cerrarSesion() async {
    _usuario = null;
    _borrador = PedidoBuilder();
    await repo.cerrarSesion();
    notifyListeners();
  }

  // ---------------- Catálogo ----------------

  List<Servicio> get servicios => catalogo.servicios();

  // ---------------- Cliente: sus pedidos ----------------

  /// Los pedidos de la persona que inició sesión, del más reciente al más antiguo.
  List<Pedido> get pedidos {
    final u = _usuario;
    if (u == null) return const <Pedido>[];
    return _ordenarRecientes(repo.pedidosDe(u.id));
  }

  Pedido? pedido(String id) => repo.pedido(id);

  Pedido? get ultimoPedido {
    final lista = pedidos;
    return lista.isEmpty ? null : lista.first;
  }

  /// Pedidos que todavía no se entregan.
  List<Pedido> get pedidosEnCurso => pedidos.where((p) => p.estado.enCurso).toList();

  /// Dirección del último pedido, para no volver a escribirla.
  String? get ultimaDireccion => ultimoPedido?.direccion;

  /// El servicio que más ha pedido la persona (mínimo 2 veces); null si no hay uno claro.
  Servicio? get servicioFavorito {
    final conteo = <String, int>{};
    for (final p in pedidos) {
      conteo[p.servicioId] = (conteo[p.servicioId] ?? 0) + 1;
    }
    String? mejor;
    var maximo = 1;
    for (final e in conteo.entries) {
      if (e.value > maximo) {
        maximo = e.value;
        mejor = e.key;
      }
    }
    return mejor == null ? null : catalogo.servicio(mejor);
  }

  /// El número es global (de todos los clientes), no solo de quien pide.
  int get siguienteNumeroPedido =>
      repo.todosLosPedidos().fold<int>(0, (m, p) => p.numero > m ? p.numero : m) + 1;

  List<Pedido> _ordenarRecientes(List<Pedido> lista) {
    lista.sort((a, b) {
      final porFecha = b.fecha.compareTo(a.fecha);
      return porFecha != 0 ? porFecha : b.numero.compareTo(a.numero);
    });
    return lista;
  }

  // ---------------- Repartidor: sus pedidos asignados ----------------

  /// Primero los que faltan (el más próximo arriba) y luego los entregados.
  List<Pedido> get pedidosAsignados {
    final u = _usuario;
    if (u == null || u.rol != RolUsuario.repartidor) return const <Pedido>[];
    final mios = repo.todosLosPedidos().where((p) => p.repartidorId == u.id).toList();
    final pendientes = mios.where((p) => p.estado.enCurso).toList()
      ..sort((a, b) => a.recoleccion.compareTo(b.recoleccion));
    final hechos = mios.where((p) => !p.estado.enCurso).toList()
      ..sort((a, b) => b.recoleccion.compareTo(a.recoleccion));
    return [...pendientes, ...hechos];
  }

  /// La próxima recolección pendiente del repartidor; null si no tiene.
  Pedido? get siguienteRecoleccion {
    for (final p in pedidosAsignados) {
      if (p.estado.enCurso) return p;
    }
    return null;
  }

  /// Guarda el peso real de la ropa y recalcula el total con el precio por kilo.
  /// Devuelve el mensaje de error, o null si se guardó.
  Future<String?> registrarPeso(String pedidoId, double kilos) async {
    final u = _usuario;
    if (u == null || u.rol != RolUsuario.repartidor) {
      return 'Solo el repartidor puede registrar el peso.';
    }
    final p = repo.pedido(pedidoId);
    if (p == null) return 'No encontramos el pedido.';
    if (p.repartidorId != u.id) return 'Este pedido no está asignado a ti.';
    if (!p.estado.enCurso) return 'Este pedido ya se entregó.';
    if (kilos.isNaN || kilos < Pedido.pesoMinimo || kilos > Pedido.pesoMaximo) {
      return 'El peso debe estar entre 0.5 y 30 kg.';
    }
    final servicio = catalogo.servicio(p.servicioId);
    if (servicio == null) return 'El servicio de este pedido ya no existe.';

    final redondeado = (kilos * 10).round() / 10; // un decimal
    await repo.guardarPedido(
      p.copiarCon(
        kilosReales: redondeado,
        totalFinal: servicio.precioPorKilo.porKilos(redondeado),
      ),
    );
    notifyListeners();
    return null;
  }

  // ---------------- Administrador: todo ----------------

  /// Todos los pedidos de todos los clientes (solo para el administrador).
  List<Pedido> get todosLosPedidos {
    if (_usuario?.rol != RolUsuario.admin) return const <Pedido>[];
    return _ordenarRecientes(repo.todosLosPedidos());
  }

  /// Todas las cuentas: primero clientes, luego repartidores y administradores.
  List<Usuario> get usuarios {
    if (_usuario?.rol != RolUsuario.admin) return const <Usuario>[];
    final lista = repo.usuarios();
    lista.sort((a, b) {
      final porRol = a.rol.index.compareTo(b.rol.index);
      return porRol != 0 ? porRol : a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });
    return lista;
  }

  List<Usuario> get repartidores =>
      usuarios.where((u) => u.rol == RolUsuario.repartidor).toList();

  Usuario? usuarioPorId(String id) => repo.usuarioPorId(id);

  /// Asigna (o cambia) el repartidor de un pedido que todavía no se entrega.
  /// Devuelve el mensaje de error, o null si se guardó.
  Future<String?> asignarRepartidor(String pedidoId, String repartidorId) async {
    final u = _usuario;
    if (u == null || u.rol != RolUsuario.admin) {
      return 'Solo el administrador puede asignar repartidores.';
    }
    final p = repo.pedido(pedidoId);
    if (p == null) return 'No encontramos el pedido.';
    if (!p.estado.enCurso) return 'Este pedido ya se entregó.';
    final r = repo.usuarioPorId(repartidorId);
    if (r == null || r.rol != RolUsuario.repartidor) return 'Elige un repartidor válido.';

    await repo.guardarPedido(p.copiarCon(repartidorId: r.id));
    notifyListeners();
    return null;
  }

  // ---------------- Borrador del pedido (cliente) ----------------

  Servicio? get servicioElegido => _borrador.servicio;
  int get kilos => _borrador.kilos;
  Dinero? get estimado => _borrador.totalEstimado;

  /// Empieza un pedido nuevo: deja elegido el servicio favorito (o el primero)
  /// para que la persona pueda continuar con un solo toque.
  void prepararNuevoPedido() {
    _borrador = _nuevoBorrador();
    final inicial = servicioFavorito ?? (servicios.isEmpty ? null : servicios.first);
    if (inicial != null) _borrador.conServicio(inicial);
    notifyListeners();
  }

  /// "Pide de nuevo": el borrador queda igual al pedido anterior.
  void repetirPedido(Pedido anterior) {
    _borrador = _nuevoBorrador();
    final servicio = catalogo.servicio(anterior.servicioId);
    if (servicio != null) _borrador.conServicio(servicio);
    _borrador.conKilos(anterior.kilos);
    notifyListeners();
  }

  void elegirServicio(Servicio servicio) {
    _borrador.conServicio(servicio);
    notifyListeners();
  }

  void cambiarKilos(int kilos) {
    _borrador.conKilos(kilos);
    notifyListeners();
  }

  /// Convierte el borrador en un pedido real y lo guarda.
  /// Lanza [DatosInvalidosException] con los mensajes si falta algo.
  Future<Pedido> confirmarPedido({
    required String direccion,
    required DateTime recoleccion,
    String? notas,
  }) async {
    final u = _usuario;
    if (u == null) throw DatosInvalidosException(['Inicia sesión para pedir.']);
    if (u.rol != RolUsuario.cliente) {
      throw DatosInvalidosException(['Solo los clientes pueden pedir una recolección.']);
    }

    _borrador
      ..conUsuario(u.id)
      ..conNumero(siguienteNumeroPedido)
      ..conDireccion(direccion)
      ..conRecoleccion(recoleccion)
      ..conNotas(notas);
    final pedido = _borrador.construir(ahora: _reloj());

    await repo.guardarPedido(pedido);
    _borrador = _nuevoBorrador();
    notifyListeners();
    return pedido;
  }

  // ---------------- Seguimiento y calificación ----------------

  /// Quién puede mover un pedido de etapa: el repartidor al que se le asignó
  /// (el flujo real), el administrador, y el cliente dueño del pedido solo como
  /// simulación para la demostración.
  bool puedeAvanzar(Pedido p) {
    final u = _usuario;
    if (u == null || !p.estado.enCurso) return false;
    switch (u.rol) {
      case RolUsuario.cliente:
        return p.usuarioId == u.id;
      case RolUsuario.repartidor:
        return p.repartidorId == u.id;
      case RolUsuario.admin:
        return true;
    }
  }

  /// Pasa el pedido a la siguiente etapa.
  Future<void> avanzarEstado(String pedidoId) async {
    final p = repo.pedido(pedidoId);
    if (p == null || !puedeAvanzar(p)) return;
    final siguiente = p.estado.siguiente;
    if (siguiente == null) return;
    await repo.guardarPedido(p.copiarCon(estado: siguiente));
    notifyListeners();
  }

  /// Devuelve el mensaje de error, o null si se guardó la calificación.
  Future<String?> calificar(String pedidoId, int estrellas, String? comentario) async {
    final u = _usuario;
    final p = repo.pedido(pedidoId);
    if (p == null) return 'No encontramos el pedido.';
    if (u == null || p.usuarioId != u.id) return 'Solo quien hizo el pedido puede calificarlo.';
    if (p.estado != EstadoPedido.entregado) {
      return 'Puedes calificar cuando el pedido esté entregado.';
    }
    if (p.calificado) return 'Este pedido ya tiene calificación.';
    if (estrellas < 1 || estrellas > 5) return 'Elige de 1 a 5 estrellas.';

    final c = comentario?.trim();
    await repo.guardarPedido(
      p.copiarCon(
        calificacion: estrellas,
        comentario: (c == null || c.isEmpty) ? null : c,
      ),
    );
    notifyListeners();
    return null;
  }

  PedidoBuilder _nuevoBorrador() {
    final b = PedidoBuilder();
    final u = _usuario;
    if (u != null) b.conUsuario(u.id);
    return b;
  }
}
