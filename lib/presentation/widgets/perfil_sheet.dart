import 'package:flutter/material.dart';

import '../../domain/value_objects/rol.dart';
import '../app_scope.dart';
import '../tema.dart';
import 'componentes.dart';

/// Hoja con los datos de la persona y el botón de cerrar sesión.
/// La usan los 3 dashboards.
void mostrarPerfil(BuildContext context) {
  final app = AppScope.leer(context);
  final usuario = app.usuario;
  if (usuario == null) return;
  final direccion = usuario.rol == RolUsuario.cliente ? app.ultimaDireccion : null;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (hoja) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: Tema.primarioSuave,
              child: Text(
                usuario.nombre.isEmpty ? '?' : usuario.nombre[0].toUpperCase(),
                style: Tema.titulo(color: Tema.primario, tamano: 30),
              ),
            ),
            const SizedBox(height: 12),
            Text(usuario.nombre, style: Tema.titulo(tamano: 22)),
            const SizedBox(height: 6),
            Pildora(texto: usuario.rol.etiqueta),
            const SizedBox(height: 8),
            Text(
              usuario.contacto.valor,
              style: Tema.cuerpo(color: Tema.textoSuave, tamano: 15),
            ),
            if (direccion != null) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_rounded, size: 18, color: Tema.primario),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      direccion,
                      textAlign: TextAlign.center,
                      style: Tema.cuerpo(tamano: 14),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(hoja).pop();
                app.cerrarSesion();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Tema.rojo,
                side: BorderSide(color: Tema.rojo.withAlpha(120)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
