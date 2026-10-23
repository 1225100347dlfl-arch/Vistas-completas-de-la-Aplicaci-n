import 'package:flutter_test/flutter_test.dart';
import 'package:lavaya/core/seguridad.dart';
import 'package:lavaya/data/adapters/catalogo_local_adapter.dart';
import 'package:lavaya/data/datos_demo.dart';
import 'package:lavaya/data/mappers.dart';
import 'package:lavaya/data/memoria_lavaya_repository.dart';
import 'package:lavaya/domain/builders/pedido_builder.dart';
import 'package:lavaya/domain/entities/servicio.dart';
import 'package:lavaya/domain/value_objects/contacto.dart';
import 'package:lavaya/domain/value_objects/dinero.dart';
import 'package:lavaya/domain/value_objects/estados.dart';
import 'package:lavaya/domain/value_objects/rol.dart';
import 'package:lavaya/presentation/app_state.dart';

final DateTime _hoy = DateTime(2026, 10, 16, 9);

Servicio _servicio(TipoServicio tipo) =>
    CatalogoLocalAdapter().servicios().firstWhere((s) => s.tipo == tipo);

AppState _nuevaApp() => AppState(
      repo: MemoriaLavaYaRepository(),
      catalogo: CatalogoLocalAdapter(),
      reloj: () => _hoy,
    );

/// App con la cuenta de ejemplo (Diana) y su sesión abierta.
Future<AppState> _appConDemo() async {
  final app = _nuevaApp();
  await sembrarDatosDemo(app.repo);
  final error = await app.iniciarSesion(correoDemo, contrasenaDemo);
  expect(error, isNull);
  return app;
}

void main() {
  group('Objetos de valor', () {
    test('Dinero formatea y multiplica', () {
      expect(const Dinero(90).texto, '\$90');
      expect(const Dinero(20) * 3, const Dinero(60));
      expect(const Dinero(30) * 0, Dinero.cero);
    });

    test('Contacto acepta correo o teléfono de 10 dígitos', () {
      expect(Contacto.tryParse('Diana@LavaYa.app')!.valor, 'diana@lavaya.app');
      expect(Contacto.tryParse('Diana@LavaYa.app')!.tipo, TipoContacto.correo);
      expect(Contacto.tryParse('449 123-4567')!.valor, '4491234567');
      expect(Contacto.tryParse('449 123-4567')!.tipo, TipoContacto.telefono);
      expect(Contacto.tryParse('12345'), isNull);
      expect(Contacto.tryParse('sin-arroba'), isNull);
      expect(Contacto.tryParse('a@b'), isNull);
    });

    test('las etapas avanzan en orden y terminan en entregado', () {
      expect(EstadoPedido.solicitado.siguiente, EstadoPedido.recogido);
      expect(EstadoPedido.enCamino.siguiente, EstadoPedido.entregado);
      expect(EstadoPedido.entregado.siguiente, isNull);
      expect(EstadoPedido.entregado.enCurso, isFalse);
      expect(EstadoPedido.enCamino.minutosRestantes, 12);
    });
  });

  group('Catálogo (Adapter)', () {
    test('con 3 kg dan los precios del prototipo', () {
      final lavado = _servicio(TipoServicio.soloLavado);
      final planchado = _servicio(TipoServicio.lavadoYPlanchado);
      expect((lavado.precioPorKilo * 3).pesos, 60);
      expect((planchado.precioPorKilo * 3).pesos, 90);
    });

    test('busca por id y devuelve null si no existe', () {
      final catalogo = CatalogoLocalAdapter();
      expect(catalogo.servicio('solo-lavado'), isNotNull);
      expect(catalogo.servicio('no-existe'), isNull);
    });
  });

  group('PedidoBuilder', () {
    PedidoBuilder completo() => PedidoBuilder()
        .conUsuario('u1')
        .conNumero(129)
        .conServicio(_servicio(TipoServicio.lavadoYPlanchado))
        .conKilos(4)
        .conDireccion('Calle Hidalgo 45, Col. Centro')
        .conRecoleccion(DateTime(2026, 10, 17, 10));

    test('construye un pedido con total = precio por kilo x kilos', () {
      final pedido = completo().conNotas('  Portón negro ').construir(ahora: _hoy);
      expect(pedido.total.pesos, 120);
      expect(pedido.kilos, 4);
      expect(pedido.estado, EstadoPedido.solicitado);
      expect(pedido.nombreServicio, 'Lavado y planchado');
      expect(pedido.notas, 'Portón negro');
      expect(pedido.fecha, _hoy);
    });

    test('las notas vacías quedan en null', () {
      expect(completo().conNotas('   ').construir(ahora: _hoy).notas, isNull);
    });

    test('los kilos se mantienen entre el mínimo y el máximo', () {
      final b = PedidoBuilder();
      expect((b..conKilos(0)).kilos, PedidoBuilder.kilosMinimos);
      expect((b..conKilos(99)).kilos, PedidoBuilder.kilosMaximos);
      expect((b..conKilos(5)).kilos, 5);
    });

    test('sin servicio no hay estimado y construir falla con mensajes', () {
      final b = PedidoBuilder().conUsuario('u1').conNumero(1);
      expect(b.totalEstimado, isNull);
      expect(b.construir, throwsA(isA<DatosInvalidosException>()));
      expect(b.validar(), contains('Elige un servicio.'));
    });

    test('rechaza una recolección que ya pasó', () {
      final b = completo().conRecoleccion(DateTime(2026, 10, 16, 8));
      expect(b.validar(ahora: _hoy).length, 1);
      expect(b.validar(), isEmpty); // sin reloj no se revisa la fecha
    });
  });

  group('Repositorio', () {
    test('guarda y recupera usuarios y pedidos, también por JSON', () async {
      final repo = MemoriaLavaYaRepository();
      await sembrarDatosDemo(repo);
      final diana = repo.usuarioPorContacto(Contacto.tryParse(correoDemo)!)!;
      expect(repo.pedidosDe(diana.id).length, 3);
      expect(repo.pedidosDe('otra').isEmpty, isTrue);

      final copia = MemoriaLavaYaRepository()..cargarDesdeJson(repo.aJson());
      expect(copia.usuarioPorId(diana.id)!.nombre, 'Diana');
      final p = copia.pedido('demo-128')!;
      expect(p.numero, 128);
      expect(p.total.pesos, 90);
      expect(p.estado, EstadoPedido.entregado);
      expect(p.calificacion, isNull);
      expect(p.notas, 'Portón negro');
      expect(pedidoDeMapa(pedidoAMapa(p)).recoleccion, p.recoleccion);
      expect(copia.usuarioPorId('demo-carlos')!.rol, RolUsuario.repartidor);
      expect(copia.pedido('demo-130')!.repartidorId, 'demo-carlos');
    });

    test('la contraseña se guarda como hash, no en claro', () async {
      final repo = MemoriaLavaYaRepository();
      await sembrarDatosDemo(repo);
      final diana = repo.usuarioPorContacto(Contacto.tryParse(correoDemo)!)!;
      expect(diana.contrasenaHash, isNot(contrasenaDemo));
      expect(diana.contrasenaHash, hashContrasena(contrasenaDemo));
    });

    test('los datos de ejemplo no se duplican', () async {
      final repo = MemoriaLavaYaRepository();
      await sembrarDatosDemo(repo);
      await sembrarDatosDemo(repo);
      final diana = repo.usuarioPorContacto(Contacto.tryParse(correoDemo)!)!;
      expect(repo.pedidosDe(diana.id).length, 3);
    });
  });

  group('Sesión (AppState)', () {
    test('entra con la cuenta de ejemplo y cierra sesión', () async {
      final app = await _appConDemo();
      expect(app.haySesion, isTrue);
      expect(app.usuario!.nombre, 'Diana');
      await app.cerrarSesion();
      expect(app.haySesion, isFalse);
      expect(app.pedidos, isEmpty);
    });

    test('rechaza datos incorrectos con un mensaje', () async {
      final app = _nuevaApp();
      await sembrarDatosDemo(app.repo);
      expect(await app.iniciarSesion('no-es-correo', 'x'), isNotNull);
      expect(await app.iniciarSesion(correoDemo, ''), 'Escribe tu contraseña.');
      expect(await app.iniciarSesion(correoDemo, 'incorrecta'), isNotNull);
      expect(app.haySesion, isFalse);
    });

    test('registra una cuenta nueva con correo o teléfono y deja la sesión abierta', () async {
      final app = _nuevaApp();
      expect(await app.registrar(nombre: 'Luis', contacto: '4491234567', contrasena: 'secreto1'), isNull);
      expect(app.usuario!.nombre, 'Luis');
      expect(app.usuario!.contacto.tipo, TipoContacto.telefono);
      expect(app.pedidos, isEmpty);
    });

    test('el registro valida nombre, contacto, contraseña y que no se repita', () async {
      final app = _nuevaApp();
      expect(await app.registrar(nombre: ' ', contacto: 'a@b.com', contrasena: '123456'), isNotNull);
      expect(await app.registrar(nombre: 'Ana', contacto: 'xx', contrasena: '123456'), isNotNull);
      expect(await app.registrar(nombre: 'Ana', contacto: 'a@b.com', contrasena: '123'), isNotNull);
      expect(await app.registrar(nombre: 'Ana', contacto: 'a@b.com', contrasena: '123456'), isNull);
      await app.cerrarSesion();
      expect(await app.registrar(nombre: 'Otra', contacto: 'A@B.com', contrasena: '123456'), isNotNull);
    });
  });

  group('Pedidos (AppState / Observer)', () {
    test('los pedidos salen del más reciente al más antiguo', () async {
      final app = await _appConDemo();
      expect(app.pedidos.map((p) => p.numero).toList(), [128, 124, 119]);
      expect(app.ultimoPedido!.numero, 128);
      expect(app.siguienteNumeroPedido, 131); // el número es global, no solo de Diana
      expect(app.ultimaDireccion, 'Calle Hidalgo 45, Col. Centro');
      expect(app.pedidosEnCurso, isEmpty);
    });

    test('el servicio favorito es el que más se ha pedido; sin pedidos no hay', () async {
      final app = await _appConDemo();
      expect(app.servicioFavorito!.tipo, TipoServicio.soloLavado);

      final vacia = _nuevaApp();
      await vacia.registrar(nombre: 'Luis', contacto: 'l@x.com', contrasena: '123456');
      expect(vacia.servicioFavorito, isNull);
      expect(vacia.ultimoPedido, isNull);
      expect(vacia.ultimaDireccion, isNull);
    });

    test('un pedido nuevo deja elegido el favorito y 3 kg', () async {
      final app = await _appConDemo();
      app.prepararNuevoPedido();
      expect(app.servicioElegido!.tipo, TipoServicio.soloLavado);
      expect(app.kilos, 3);
      expect(app.estimado!.pesos, 60);
    });

    test('elegir servicio y kilos actualiza el estimado y avisa a las pantallas', () async {
      final app = await _appConDemo();
      app.prepararNuevoPedido();

      var avisos = 0;
      app.addListener(() => avisos++);

      app.elegirServicio(_servicio(TipoServicio.lavadoYPlanchado));
      expect(app.estimado!.pesos, 90);
      app.cambiarKilos(5);
      expect(app.estimado!.pesos, 150);
      expect(avisos, 2);
    });

    test('"Pide de nuevo" copia el servicio y los kilos del pedido anterior', () async {
      final app = await _appConDemo();
      app.repetirPedido(app.ultimoPedido!);
      expect(app.servicioElegido!.tipo, TipoServicio.lavadoYPlanchado);
      expect(app.kilos, 3);
      expect(app.estimado!.pesos, 90);
    });

    test('confirmar crea el pedido #131 en etapa "solicitado" y vacía el borrador', () async {
      final app = await _appConDemo();
      app.prepararNuevoPedido();
      final pedido = await app.confirmarPedido(
        direccion: 'Av. Juárez 10, Col. Centro',
        recoleccion: DateTime(2026, 10, 17, 10, 30),
        notas: 'Tocar el timbre 2',
      );
      expect(pedido.numero, 131);
      expect(pedido.estado, EstadoPedido.solicitado);
      expect(pedido.total.pesos, 60);
      expect(app.pedidosEnCurso.single.id, pedido.id);
      expect(app.pedido(pedido.id)!.notas, 'Tocar el timbre 2');
      expect(app.servicioElegido, isNull);
      expect(app.siguienteNumeroPedido, 132);
    });

    test('confirmar falla si la recolección ya pasó o falta la dirección', () async {
      final app = await _appConDemo();
      app.prepararNuevoPedido();
      await expectLater(
        app.confirmarPedido(direccion: 'Av. Juárez 10', recoleccion: DateTime(2026, 10, 16, 8)),
        throwsA(isA<DatosInvalidosException>()),
      );
      await expectLater(
        app.confirmarPedido(direccion: '  ', recoleccion: DateTime(2026, 10, 17, 8)),
        throwsA(isA<DatosInvalidosException>()),
      );
      expect(app.pedidos.length, 3);
    });
  });

  group('Seguimiento y calificación', () {
    Future<(AppState, String)> conPedidoNuevo() async {
      final app = await _appConDemo();
      app.prepararNuevoPedido();
      final p = await app.confirmarPedido(
        direccion: 'Av. Juárez 10, Col. Centro',
        recoleccion: DateTime(2026, 10, 17, 10),
      );
      return (app, p.id);
    }

    test('avanza por todas las etapas y se detiene al entregar', () async {
      final (app, id) = await conPedidoNuevo();
      final vistas = <EstadoPedido>[app.pedido(id)!.estado];
      for (var i = 0; i < 6; i++) {
        await app.avanzarEstado(id);
        vistas.add(app.pedido(id)!.estado);
      }
      expect(vistas.take(5).toList(), EstadoPedido.values);
      expect(vistas.last, EstadoPedido.entregado);
      expect(app.pedidosEnCurso, isEmpty);
    });

    test('solo se califica un pedido entregado, una vez y de 1 a 5', () async {
      final (app, id) = await conPedidoNuevo();
      expect(await app.calificar(id, 5, null), isNotNull); // aún no se entrega
      for (var i = 0; i < 4; i++) {
        await app.avanzarEstado(id);
      }
      expect(await app.calificar(id, 0, null), isNotNull);
      expect(await app.calificar(id, 6, null), isNotNull);
      expect(await app.calificar(id, 4, '  Todo bien  '), isNull);
      expect(app.pedido(id)!.calificacion, 4);
      expect(app.pedido(id)!.comentario, 'Todo bien');
      expect(await app.calificar(id, 5, null), isNotNull); // ya calificado
      expect(app.pedido(id)!.calificacion, 4);
    });

    test('el pedido #128 de ejemplo espera calificación', () async {
      final app = await _appConDemo();
      expect(app.pedido('demo-128')!.calificado, isFalse);
      expect(await app.calificar('demo-128', 4, null), isNull);
      expect(app.pedido('demo-128')!.calificado, isTrue);
    });
  });
  group('Tipos de usuario (roles)', () {
    Future<AppState> como(String correo) async {
      final app = _nuevaApp();
      await sembrarDatosDemo(app.repo);
      expect(await app.iniciarSesion(correo, contrasenaDemo), isNull);
      return app;
    }

    test('cada cuenta de ejemplo entra con su rol', () async {
      expect((await como(correoDemo)).rol, RolUsuario.cliente);
      expect((await como(correoRepartidorDemo)).rol, RolUsuario.repartidor);
      expect((await como(correoAdminDemo)).rol, RolUsuario.admin);
    });

    test('el registro guarda el rol elegido', () async {
      final app = _nuevaApp();
      expect(
        await app.registrar(
          nombre: 'Rosa',
          contacto: 'rosa@x.com',
          contrasena: '123456',
          rol: RolUsuario.repartidor,
        ),
        isNull,
      );
      expect(app.rol, RolUsuario.repartidor);
      expect(app.pedidosAsignados, isEmpty); // estado vacío de un repartidor nuevo
      expect(app.siguienteRecoleccion, isNull);
    });

    test('cada rol solo ve sus propios datos', () async {
      final cliente = await como(correoDemo);
      expect(cliente.todosLosPedidos, isEmpty);
      expect(cliente.usuarios, isEmpty);
      expect(cliente.pedidosAsignados, isEmpty);

      final admin = await como(correoAdminDemo);
      expect(admin.todosLosPedidos.length, 5);
      expect(admin.usuarios.length, 4);
      expect(admin.repartidores.single.nombre, 'Carlos');
      expect(admin.pedidos, isEmpty); // el admin no tiene pedidos propios
    });

    test('el repartidor ve primero lo pendiente y luego lo entregado', () async {
      final carlos = await como(correoRepartidorDemo);
      expect(carlos.pedidosAsignados.map((p) => p.numero).toList(), [130, 128, 124, 119]);
      expect(carlos.siguienteRecoleccion!.numero, 130);
    });

    test('el administrador asigna un repartidor y aparece en la lista de Carlos', () async {
      final admin = await como(correoAdminDemo);
      expect(admin.todosLosPedidos.where((p) => p.estado.enCurso && !p.asignado).single.numero, 129);

      var avisos = 0;
      admin.addListener(() => avisos++);
      expect(await admin.asignarRepartidor('demo-129', 'demo-carlos'), isNull);
      expect(avisos, 1);
      expect(admin.pedido('demo-129')!.repartidorId, 'demo-carlos');

      final carlos = AppState(repo: admin.repo, catalogo: CatalogoLocalAdapter(), reloj: () => _hoy);
      expect(await carlos.iniciarSesion(correoRepartidorDemo, contrasenaDemo), isNull);
      // el #130 es el 19 oct y el #129 el 20 oct: el más próximo va primero
      expect(carlos.pedidosAsignados.take(2).map((p) => p.numero).toList(), [130, 129]);
    });

    test('asignar valida el rol, el pedido y el repartidor', () async {
      final cliente = await como(correoDemo);
      expect(await cliente.asignarRepartidor('demo-129', 'demo-carlos'), isNotNull);

      final admin = await como(correoAdminDemo);
      expect(await admin.asignarRepartidor('no-existe', 'demo-carlos'), isNotNull);
      expect(await admin.asignarRepartidor('demo-128', 'demo-carlos'), isNotNull); // ya entregado
      expect(await admin.asignarRepartidor('demo-129', 'demo-diana'), isNotNull); // no es repartidor
      expect(admin.pedido('demo-129')!.repartidorId, isNull);
    });

    test('registrar el peso recalcula el total con el precio por kilo', () async {
      final carlos = await como(correoRepartidorDemo);
      expect(carlos.pedido('demo-130')!.totalVigente.pesos, 150); // estimado: 5 kg x $30
      expect(await carlos.registrarPeso('demo-130', 4.5), isNull);
      final p = carlos.pedido('demo-130')!;
      expect(p.kilosReales, 4.5);
      expect(p.totalVigente.pesos, 135);
      expect(p.total.pesos, 150); // el estimado original no se pierde
      expect(p.pesado, isTrue);
      // un decimal: 4.26 -> 4.3 kg
      expect(await carlos.registrarPeso('demo-130', 4.26), isNull);
      expect(carlos.pedido('demo-130')!.kilosReales, 4.3);
      expect(carlos.pedido('demo-130')!.totalVigente.pesos, 129);
    });

    test('registrar el peso valida límites, dueño y rol', () async {
      final carlos = await como(correoRepartidorDemo);
      expect(await carlos.registrarPeso('demo-130', 0.2), isNotNull);
      expect(await carlos.registrarPeso('demo-130', 31), isNotNull);
      expect(await carlos.registrarPeso('demo-130', double.nan), isNotNull);
      expect(await carlos.registrarPeso('demo-129', 3), isNotNull); // no está asignado a Carlos
      expect(await carlos.registrarPeso('demo-128', 3), isNotNull); // ya entregado
      expect(carlos.pedido('demo-130')!.pesado, isFalse);

      final admin = await como(correoAdminDemo);
      expect(await admin.registrarPeso('demo-130', 3), isNotNull);
    });

    test('quién puede avanzar un pedido de etapa', () async {
      final carlos = await como(correoRepartidorDemo);
      expect(carlos.puedeAvanzar(carlos.pedido('demo-130')!), isTrue);
      expect(carlos.puedeAvanzar(carlos.pedido('demo-129')!), isFalse); // sin asignar
      await carlos.avanzarEstado('demo-130');
      expect(carlos.pedido('demo-130')!.estado, EstadoPedido.enProceso);
      await carlos.avanzarEstado('demo-129'); // no hace nada
      expect(carlos.pedido('demo-129')!.estado, EstadoPedido.solicitado);

      final diana = await como(correoDemo);
      expect(diana.puedeAvanzar(diana.pedido('demo-130')!), isFalse); // es de Mariana
    });

    test('solo el cliente dueño califica y solo un cliente puede pedir', () async {
      final carlos = await como(correoRepartidorDemo);
      expect(await carlos.calificar('demo-128', 5, null), isNotNull);

      await expectLater(
        carlos.confirmarPedido(
          direccion: 'Av. Juárez 10, Col. Centro',
          recoleccion: DateTime(2026, 10, 17, 10),
        ),
        throwsA(isA<DatosInvalidosException>()),
      );
    });
  });
}
