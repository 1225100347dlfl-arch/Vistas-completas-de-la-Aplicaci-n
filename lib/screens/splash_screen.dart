import 'package:flutter/material.dart';

import '../presentation/tema.dart';
import 'auth_gate.dart';

/// Pantalla de carga inicial: logo animado y paso al Login (o al dashboard
/// si ya había una sesión abierta).
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.duracion = const Duration(milliseconds: 350),
    this.inicializacion,
  });

  final Duration duracion;
  final Future<void>? inicializacion;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _errorInicializacion = false;

  @override
  void initState() {
    super.initState();
    _esperarInicializacion();
  }

  Future<void> _esperarInicializacion() async {
    try {
      await Future.wait<void>([
        if (widget.inicializacion != null) widget.inicializacion!,
        Future<void>.delayed(widget.duracion),
      ]);
      _continuar();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'arranque de LavaYa',
        ),
      );
      if (mounted) setState(() => _errorInicializacion = true);
    }
  }

  void _continuar() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: '/inicio'),
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionsBuilder: (_, animacion, __, hijo) =>
            FadeTransition(opacity: animacion, child: hijo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: Tema.degradado),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.6, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                builder: (context, escala, hijo) => Opacity(
                  opacity: escala.clamp(0.0, 1.0).toDouble(),
                  child: Transform.scale(scale: escala, child: hijo),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'LY',
                          style: Tema.titulo(color: Tema.primario, tamano: 42),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text('LavaYa', style: Tema.titulo(color: Colors.white, tamano: 38)),
                    const SizedBox(height: 6),
                    Text(
                      'Tu ropa limpia, sin salir de casa',
                      style: Tema.cuerpo(color: Colors.white.withAlpha(225), tamano: 16),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              if (_errorInicializacion)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'No se pudo iniciar LavaYa. Cierra y vuelve a abrir la aplicación.',
                    textAlign: TextAlign.center,
                    style: Tema.cuerpo(color: Colors.white, tamano: 14),
                  ),
                )
              else
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
