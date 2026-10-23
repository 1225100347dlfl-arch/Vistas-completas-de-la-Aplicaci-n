import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Hash de la contraseña (nunca se guarda en claro).
/// Nota: para producción usar un algoritmo con sal (bcrypt/argon2) en un servidor.
String hashContrasena(String contrasena) =>
    sha256.convert(utf8.encode(contrasena)).toString();
