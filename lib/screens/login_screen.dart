import 'package:flutter/material.dart';

import '../data/datos_demo.dart';
import '../domain/value_objects/contacto.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import 'rutas.dart';

/// 1. "Login / Registro": entrar con correo o teléfono y contraseña.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _contacto = TextEditingController();
  final _clave = TextEditingController();
  bool _oculta = true;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _contacto.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final app = AppScope.leer(context);
    setState(() {
      _enviando = true;
      _error = null;
    });
    final error = await app.iniciarSesion(_contacto.text, _clave.text);
    // Si salió bien, AuthGate cambia a Home y esta pantalla desaparece.
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _error = error;
    });
  }

  void _usarCuentaDemo(String correo) {
    setState(() {
      _contacto.text = correo;
      _clave.text = contrasenaDemo;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tema.fondo,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                children: [
                  const _Logo(),
                  const SizedBox(height: 14),
                  Text('LavaYa', style: Tema.titulo(tamano: 30)),
                  const SizedBox(height: 4),
                  Text(
                    'Tu ropa limpia, sin salir de casa',
                    style: Tema.cuerpo(color: Tema.textoSuave, tamano: 15.5),
                  ),
                  const SizedBox(height: 28),
                  LavaTarjeta(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Iniciar sesión', style: Tema.titulo(tamano: 21)),
                          const SizedBox(height: 18),
                          LavaCampo(
                            etiqueta: 'Correo o teléfono',
                            controller: _contacto,
                            hint: 'ejemplo@correo.com',
                            icono: Icons.person_outline_rounded,
                            teclado: TextInputType.emailAddress,
                            accion: TextInputAction.next,
                            validator: (v) => Contacto.tryParse(v ?? '') == null
                                ? 'Escribe un correo o un teléfono de 10 dígitos.'
                                : null,
                          ),
                          LavaCampo(
                            etiqueta: 'Contraseña',
                            controller: _clave,
                            hint: 'Tu contraseña',
                            icono: Icons.lock_outline_rounded,
                            obscuro: _oculta,
                            accion: TextInputAction.done,
                            onEnviado: (_) => _entrar(),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Escribe tu contraseña.' : null,
                            sufijo: TextButton(
                              onPressed: () => setState(() => _oculta = !_oculta),
                              child: Text(_oculta ? 'Mostrar' : 'Ocultar'),
                            ),
                          ),
                          if (_error != null) MensajeError(_error!),
                          FilledButton(
                            onPressed: _enviando ? null : _entrar,
                            child: _enviando
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 3),
                                  )
                                : const Text('Entrar'),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '¿No tienes cuenta?',
                                style: Tema.cuerpo(color: Tema.textoSuave, tamano: 14),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pushNamed(rutaRegistro),
                                child: const Text('Crear cuenta'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _CuentasDemo(onUsar: _usarCuentaDemo),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: Tema.degradado,
        boxShadow: Tema.sombraSuave,
      ),
      child: Center(
        child: Text(
          'LY',
          style: Tema.titulo(color: Colors.white, tamano: 32),
        ),
      ),
    );
  }
}

/// Atajo para la demostración: llena el formulario con la cuenta de ejemplo
/// de cada tipo de usuario (cliente, repartidor y administrador).
class _CuentasDemo extends StatelessWidget {
  const _CuentasDemo({required this.onUsar});

  final ValueChanged<String> onUsar;

  @override
  Widget build(BuildContext context) {
    return LavaTarjeta(
      color: Tema.primarioSuave,
      bordeColor: Tema.primario.withAlpha(60),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, color: Tema.primario),
              const SizedBox(width: 10),
              Text('Cuentas de ejemplo', style: Tema.subtitulo(tamano: 15)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Contraseña de todas: $contrasenaDemo',
            style: Tema.cuerpo(color: Tema.textoSuave, tamano: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.person_rounded, size: 18),
                label: const Text('Cliente'),
                onPressed: () => onUsar(correoDemo),
              ),
              ActionChip(
                avatar: const Icon(Icons.delivery_dining_rounded, size: 18),
                label: const Text('Repartidor'),
                onPressed: () => onUsar(correoRepartidorDemo),
              ),
              ActionChip(
                avatar: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                label: const Text('Administrador'),
                onPressed: () => onUsar(correoAdminDemo),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
