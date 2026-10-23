import 'package:flutter/material.dart';

import '../../domain/value_objects/rol.dart';
import '../tema.dart';
import 'componentes.dart';

/// Encabezado de los dashboards del repartidor y del administrador:
/// etiqueta del rol, saludo, subtítulo y el avatar que abre el perfil.
class EncabezadoDashboard extends StatelessWidget {
  const EncabezadoDashboard({
    super.key,
    required this.nombre,
    required this.subtitulo,
    required this.rol,
    required this.onPerfil,
  });

  final String nombre;
  final String subtitulo;
  final RolUsuario rol;
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
              Pildora(texto: rol.etiqueta),
              const SizedBox(height: 10),
              Text('Hola, $nombre', style: Tema.titulo(tamano: 28)),
              const SizedBox(height: 4),
              Text(subtitulo, style: Tema.cuerpo(color: Tema.textoSuave, tamano: 16)),
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
                  child: Text(inicial, style: Tema.subtitulo(color: Tema.primario, tamano: 20)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Número grande con su etiqueta (resumen del dashboard).
class TarjetaStat extends StatelessWidget {
  const TarjetaStat({
    super.key,
    required this.icono,
    required this.valor,
    required this.etiqueta,
    this.color = Tema.primario,
    this.fondo = Tema.primarioSuave,
  });

  final IconData icono;
  final int valor;
  final String etiqueta;
  final Color color;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    return LavaTarjeta(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconoBurbuja(icono: icono, color: color, fondo: fondo, tamano: 40),
          const SizedBox(height: 12),
          Text('$valor', style: Tema.titulo(tamano: 30)),
          const SizedBox(height: 2),
          Text(etiqueta, style: Tema.cuerpo(color: Tema.textoSuave, tamano: 13.5)),
        ],
      ),
    );
  }
}

/// Acceso grande a una lista o pantalla (con flecha a la derecha).
class AccesoLista extends StatelessWidget {
  const AccesoLista({
    super.key,
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
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      onTap: onTap,
      child: Row(
        children: [
          IconoBurbuja(icono: icono),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Tema.subtitulo()),
                const SizedBox(height: 2),
                Text(subtitulo, style: Tema.cuerpo(color: Tema.textoSuave, tamano: 13.5)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Tema.textoSuave),
        ],
      ),
    );
  }
}
