import '../entities/servicio.dart';

/// Puerto para obtener los servicios que se pueden pedir.
/// Se implementa con un Adapter (ver data/adapters). Hoy: una lista fija.
/// Mañana: un servidor, sin tocar las pantallas.
abstract class CatalogoService {
  List<Servicio> servicios();

  Servicio? servicio(String id);
}
