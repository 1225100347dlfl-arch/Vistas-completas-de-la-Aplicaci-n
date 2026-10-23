/// Fuente de la hora actual. Se inyecta para poder probar con horas fijas.
typedef Reloj = DateTime Function();

DateTime relojSistema() => DateTime.now();
