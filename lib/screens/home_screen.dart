import 'package:flutter/material.dart';

import '../core/fechas.dart';
import '../domain/entities/pedido.dart';
import '../domain/value_objects/estados.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import '../presentation/widgets/perfil_sheet.dart';
import 'rutas.dart';

/// "Home": lo primero que ve la persona. Una sola acción principal (Pedir servicio),
/// un atajo para repetir el último pedido y una explicación de 3 pasos.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _pedirServicio(BuildContext context) {
    AppScope.leer(context).prepararNuevoPedido();
    Navigator.of(context).pushNamed(rutaServicio);
  }

  void _repetir(BuildContext context, Pedido pedido) {
    AppScope.leer(context).repetirPedido(pedido);
    Navigator.of(context).pushNamed(rutaServicio);
  }

  void _verSeguimiento(BuildContext context, Pedido pedido) {
    Navigator.of(context).pushNamed(rutaSeguimiento, arguments: pedido.id);
  }

  void _verHistorial(BuildContext context) {
    Navigator.of(context).pushNamed(rutaHistorial);
  }

  void _verPerfil(BuildContext context) => mostrarPerfil(context);

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final nombre = app.usuario?.nombre ?? 'invitado';
    final ultimo = app.ultimoPedido;
    final enCurso = app.pedidosEnCurso;

    return Scaffold(
      backgroundColor: Tema.fondo,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            _Encabezado(
              nombre: nombre,
              onPerfil: () => _verPerfil(context),
            ),
            const SizedBox(height: 22),
            for (final p in enCurso) ...[
              _EnCurso(pedido: p, onVer: () => _verSeguimiento(context, p)),
              const SizedBox(height: 16),
            ],
            _HeroPedir(onPedir: () => _pedirServicio(context)),
            if (ultimo != null) ...[
              const SizedBox(height: 18),
              _PideDeNuevo(pedido: ultimo, onRepetir: () => _repetir(context, ultimo)),
            ],
            const SizedBox(height: 18),
            const _ComoFunciona(),
            const SizedBox(height: 18),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Acceso(
                      icono: Icons.history_rounded,
                      titulo: 'Historial',
                      subtitulo: 'Tus pedidos anteriores',
                      onTap: () => _verHistorial(context),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _Acceso(
                      icono: Icons.person_rounded,
                      titulo: 'Perfil',
                      subtitulo: 'Tus datos y direcciones',
                      onTap: () => _verPerfil(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.nombre, required this.onPerfil});

  final String nombre;
  final VoidCallback onPerfil;

  @override
  Widget build(BuildContext context) {
    final inicial = nombre.isEmpty ? '?' : nombre[0].toUpperCase();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hola, $nombre', style: Tema.titulo(tamano: 28)),
              const SizedBox(height: 4),
              Text('¿Qué quieres lavar hoy?', style: Tema.cuerpo(color: Tema.textoSuave, tamano: 16)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: 'Perfil de $nombre',
          child: Material(
            color: Tema.primarioSuave,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPerfil,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Text(
                    inicial,
                    style: Tema.subtitulo(color: Tema.primario, tamano: 20),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Circulo extends StatelessWidget {
  const _Circulo({required this.tamano, required this.alpha});

  final double tamano;
  final int alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha(alpha),
      ),
    );
  }
}

/// La acción principal de la app, en grande y con color.
class _HeroPedir extends StatelessWidget {
  const _HeroPedir({required this.onPedir});

  final VoidCallback onPedir;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: const BoxDecoration(gradient: Tema.degradado),
        child: Stack(
          children: [
            Positioned(right: -30, top: -30, child: _Circulo(tamano: 150, alpha: 30)),
            Positioned(right: 50, bottom: -60, child: _Circulo(tamano: 120, alpha: 22)),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Pildora(
                    texto: 'Recolección a domicilio',
                    icono: Icons.local_shipping_rounded,
                    color: Colors.white,
                    fondo: Colors.white.withAlpha(46),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ropa limpia,\nsin salir de casa',
                    style: Tema.titulo(color: Colors.white, tamano: 29),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pasamos por tu ropa y te la llevamos lista.',
                    style: Tema.cuerpo(color: Colors.white.withAlpha(225), tamano: 15.5),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: onPedir,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Pedir servicio'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Tema.primario,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pedido que todavía no llega: estado, tiempo estimado y acceso al seguimiento.
class _EnCurso extends StatelessWidget {
  const _EnCurso({required this.pedido, required this.onVer});

  final Pedido pedido;
  final VoidCallback onVer;

  @override
  Widget build(BuildContext context) {
    return LavaTarjeta(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      color: Tema.ambarSuave,
      bordeColor: Tema.ambar.withAlpha(70),
      onTap: onVer,
      child: Row(
        children: [
          const IconoBurbuja(
            icono: Icons.local_shipping_rounded,
            color: Tema.ambar,
            fondo: Colors.white,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pedido #${pedido.numero} · ${pedido.estado.etiqueta}', style: Tema.subtitulo()),
                const SizedBox(height: 2),
                Text(
                  'Tiempo estimado: ${pedido.estado.minutosRestantes} min',
                  style: Tema.cuerpo(color: Tema.textoSuave, tamano: 14),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onVer, child: const Text('Ver')),
        ],
      ),
    );
  }
}

/// Atajo: repetir el último pedido con un toque.
class _PideDeNuevo extends StatelessWidget {
  const _PideDeNuevo({required this.pedido, required this.onRepetir});

  final Pedido pedido;
  final VoidCallback onRepetir;

  @override
  Widget build(BuildContext context) {
    return LavaTarjeta(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      onTap: onRepetir,
      child: Row(
        children: [
          const IconoBurbuja(icono: Icons.replay_rounded),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pide de nuevo', style: Tema.etiqueta()),
                const SizedBox(height: 2),
                Text(pedido.nombreServicio, style: Tema.subtitulo()),
                Text(
                  '${pedido.kilos} kg · ${pedido.total.texto} aprox. · ${formatoFechaCorta(pedido.fecha)}',
                  style: Tema.cuerpo(color: Tema.textoSuave, tamano: 13.5),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onRepetir, child: const Text('Repetir')),
        ],
      ),
    );
  }
}

class _ComoFunciona extends StatelessWidget {
  const _ComoFunciona();

  @override
  Widget build(BuildContext context) {
    return LavaTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Así funciona', style: Tema.subtitulo()),
          const SizedBox(height: 16),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Paso(icono: Icons.touch_app_rounded, texto: 'Eliges tu servicio')),
              Expanded(child: _Paso(icono: Icons.local_shipping_rounded, texto: 'Recogemos tu ropa')),
              Expanded(child: _Paso(icono: Icons.home_rounded, texto: 'Te la entregamos limpia')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconoBurbuja(icono: icono, tamano: 52),
        const SizedBox(height: 10),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: Tema.cuerpo(color: Tema.textoSuave, tamano: 13),
        ),
      ],
    );
  }
}

class _Acceso extends StatelessWidget {
  const _Acceso({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LavaTarjeta(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconoBurbuja(icono: icono, tamano: 44),
          const SizedBox(height: 12),
          Text(titulo, style: Tema.subtitulo()),
          const SizedBox(height: 2),
          Text(subtitulo, style: Tema.cuerpo(color: Tema.textoSuave, tamano: 13)),
        ],
      ),
    );
  }
}
