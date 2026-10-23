enum TipoContacto { correo, telefono }

/// Correo o teléfono con el que se entra a la app ("Correo o teléfono" del Login).
class Contacto {
  const Contacto._(this.tipo, this.valor);

  final TipoContacto tipo;

  /// Correo en minúsculas, o teléfono solo con dígitos.
  final String valor;

  static final RegExp _correo = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Devuelve null si no es un correo válido ni un teléfono de 10 dígitos.
  static Contacto? tryParse(String texto) {
    final limpio = texto.trim().toLowerCase();
    if (_correo.hasMatch(limpio)) return Contacto._(TipoContacto.correo, limpio);
    final digitos = limpio.replaceAll(RegExp(r'[\s\-().]'), '');
    if (RegExp(r'^\d{10}$').hasMatch(digitos)) {
      return Contacto._(TipoContacto.telefono, digitos);
    }
    return null;
  }

  /// Para reconstruir desde lo guardado.
  factory Contacto.deGuardado(String tipo, String valor) =>
      Contacto._(TipoContacto.values.byName(tipo), valor);

  @override
  bool operator ==(Object other) =>
      other is Contacto && other.tipo == tipo && other.valor == valor;

  @override
  int get hashCode => Object.hash(tipo, valor);

  @override
  String toString() => valor;
}
