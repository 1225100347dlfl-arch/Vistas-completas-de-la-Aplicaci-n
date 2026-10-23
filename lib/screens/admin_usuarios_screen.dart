import 'package:flutter/material.dart';

import '../domain/entities/usuario.dart';
import '../domain/value_objects/estados.dart';
import '../domain/value_objects/rol.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';

/// Lista secundaria del ADMINISTRADOR: todas las cuentas, con filtro por tipo
/// de usuario y estado vacío.
class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});

  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  /// null = todos.
  RolUsuario? _filtro;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final todos = app.usuarios;
    final lista = _filtro == null ? todos : todos.where((u) => u.rol == _filtro).toList();
    final pedidos = app.todosLosPedidos;

    String resumen(Usuario u) {
      switch (u.rol) {
        case RolUsuario.cliente:
          final n = pedidos.where((p) => p.usuarioId == u.id).length;
          return n == 1 ? '1 pedido' : '$n pedidos';
        case RolUsuario.repartidor:
          final n = pedidos.where((p) => p.repartidorId == u.id && p.estado.enCurso).length;
          return n == 1 ? '1 por atender' : '$n por atender';
        case RolUsuario.admin:
          return 'Acceso total';
      }
    }

    return Scaffold(
      backgroundColor: Tema.fondo,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                CabeceraPantalla(
                  titulo: 'Usuarios',
                  subtitulo: todos.length == 1 ? '1 cuenta' : '${todos.length} cuentas',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: _filtro == null,
                          onSelected: (_) => setState(() => _filtro = null),
                        ),
                        for (final r in RolUsuario.values)
                          ChoiceChip(
                            label: Text(r.etiqueta),
                            selected: _filtro == r,
                            onSelected: (_) => setState(() => _filtro = r),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: lista.isEmpty
                      ? const _Vacio()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                          itemCount: lista.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final u = lista[i];
                            return LavaTarjeta(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Tema.primarioSuave,
                                    child: Text(
                                      u.nombre.isEmpty ? '?' : u.nombre[0].toUpperCase(),
                                      style: Tema.subtitulo(color: Tema.primario, tamano: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(u.nombre, style: Tema.subtitulo()),
                                        Text(
                                          u.contacto.valor,
                                          style: Tema.cuerpo(color: Tema.textoSuave, tamano: 13.5),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(resumen(u), style: Tema.etiqueta()),
                                      ],
                                    ),
                                  ),
                                  Pildora(texto: u.rol.etiqueta),
                                ],
                              ),
                            );
                          },
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

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconoBurbuja(icono: Icons.group_off_rounded, tamano: 64),
            const SizedBox(height: 16),
            Text(
              'No hay usuarios de este tipo',
              textAlign: TextAlign.center,
              style: Tema.subtitulo(),
            ),
          ],
        ),
      ),
    );
  }
}
