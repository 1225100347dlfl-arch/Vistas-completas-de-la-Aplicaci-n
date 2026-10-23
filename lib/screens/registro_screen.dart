import 'package:flutter/material.dart';

import '../domain/value_objects/contacto.dart';
import '../domain/value_objects/rol.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';

/// Crear cuenta: nombre, correo o teléfono y contraseña.
/// Al terminar la sesión queda abierta y se vuelve al Home.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _contacto = TextEditingController();
  final _clave = TextEditingController();
  final _repetir = TextEditingController();
  RolUsuario _rol = RolUsuario.cliente;
  bool _oculta = true;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _contacto.dispose();
    _clave.dispose();
    _repetir.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final app = AppScope.leer(context);
    final nav = Navigator.of(context);
    setState(() {
      _enviando = true;
      _error = null;
    });
    final error = await app.registrar(
      nombre: _nombre.text,
      contacto: _contacto.text,
      contrasena: _clave.text,
      rol: _rol,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _enviando = false;
        _error = error;
      });
      return;
    }
    // La sesión ya quedó abierta: AuthGate muestra el Home. Se cierra esta pantalla.
    nav.popUntil((ruta) => ruta.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tema.fondo,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                const CabeceraPantalla(
                  titulo: 'Crear cuenta',
                  subtitulo: 'Solo te toma un minuto',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: LavaTarjeta(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tipo de usuario',
                              style: Tema.cuerpo(tamano: 14).copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            for (final rol in RolUsuario.values)
                              _OpcionRol(
                                rol: rol,
                                seleccionado: _rol == rol,
                                onTap: () => setState(() => _rol = rol),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'Para la demostración se puede elegir cualquier tipo de usuario.',
                              style: Tema.cuerpo(color: Tema.textoSuave, tamano: 12.5),
                            ),
                            const SizedBox(height: 18),
                            LavaCampo(
                              etiqueta: 'Nombre',
                              controller: _nombre,
                              hint: 'Cómo te llamas',
                              icono: Icons.badge_outlined,
                              accion: TextInputAction.next,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Escribe tu nombre.' : null,
                            ),
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
                              hint: 'Mínimo 6 caracteres',
                              icono: Icons.lock_outline_rounded,
                              obscuro: _oculta,
                              accion: TextInputAction.next,
                              validator: (v) => (v == null || v.length < 6)
                                  ? 'La contraseña debe tener al menos 6 caracteres.'
                                  : null,
                              sufijo: TextButton(
                                onPressed: () => setState(() => _oculta = !_oculta),
                                child: Text(_oculta ? 'Mostrar' : 'Ocultar'),
                              ),
                            ),
                            LavaCampo(
                              etiqueta: 'Repite tu contraseña',
                              controller: _repetir,
                              hint: 'Otra vez la contraseña',
                              icono: Icons.lock_outline_rounded,
                              obscuro: _oculta,
                              accion: TextInputAction.done,
                              onEnviado: (_) => _crear(),
                              validator: (v) =>
                                  v != _clave.text ? 'Las contraseñas no coinciden.' : null,
                            ),
                            if (_error != null) MensajeError(_error!),
                            FilledButton(
                              onPressed: _enviando ? null : _crear,
                              child: _enviando
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 3),
                                    )
                                  : const Text('Crear cuenta'),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _iconoDeRol(RolUsuario rol) {
  switch (rol) {
    case RolUsuario.cliente:
      return Icons.person_rounded;
    case RolUsuario.repartidor:
      return Icons.delivery_dining_rounded;
    case RolUsuario.admin:
      return Icons.admin_panel_settings_rounded;
  }
}

/// Opción tocable para elegir el tipo de usuario al registrarse.
class _OpcionRol extends StatelessWidget {
  const _OpcionRol({required this.rol, required this.seleccionado, required this.onTap});

  final RolUsuario rol;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: seleccionado,
        label: '${rol.etiqueta}. ${rol.descripcion}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: seleccionado ? Tema.primarioSuave : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: seleccionado ? Tema.primario : Tema.borde,
              width: seleccionado ? 2 : 1.2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconoBurbuja(
                      icono: _iconoDeRol(rol),
                      tamano: 42,
                      fondo: seleccionado ? Colors.white : Tema.primarioSuave,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rol.etiqueta, style: Tema.subtitulo(tamano: 16)),
                          Text(
                            rol.descripcion,
                            style: Tema.cuerpo(color: Tema.textoSuave, tamano: 13),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      seleccionado
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: seleccionado ? Tema.primario : Tema.borde,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
