// Utilidades de seguridad de las cuentas de FinanzApp.
//
// Las contrasenas NUNCA se guardan en texto plano: se almacena el hash
// SHA-256 de "email|contrasena". El email actua como sal, de modo que dos
// cuentas con la misma contrasena tienen hashes distintos.
//
// Las cuentas creadas por versiones anteriores guardan la contrasena en
// claro: `contrasenaCorrecta` las sigue aceptando y `requiereMigracion`
// avisa que hay que guardarlas hasheadas en el proximo login.

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../model/model.dart';

/// Hashea una contrasena con SHA-256 usando el email como sal.
/// El email se normaliza (minusculas) para que el resultado no dependa de
/// como el usuario tipeo su correo al registrarse.
String hashContrasena(String email, String password) {
  final String normalizado = email.trim().toLowerCase();
  final List<int> bytes = utf8.encode('$normalizado|$password');
  return sha256.convert(bytes).toString();
}

/// Devuelve true si el valor guardado tiene la forma de un hash SHA-256
/// (64 caracteres hexadecimales), es decir, si la cuenta ya esta protegida.
bool esHashContrasena(String valor) {
  return RegExp(r'^[0-9a-f]{64}$').hasMatch(valor);
}

/// Compara la contrasena ingresada contra la guardada en la cuenta.
/// Si la cuenta esta migrada compara hashes; si conserva la contrasena en
/// claro (cuenta vieja) compara directo.
bool contrasenaCorrecta(Usuario usuario, String password) {
  if (esHashContrasena(usuario.password)) {
    return usuario.password == hashContrasena(usuario.email, password);
  }
  return usuario.password == password;
}

/// Devuelve true si la contrasena de la cuenta todavia esta en texto plano
/// y hay que volver a guardarla hasheada.
bool requiereMigracion(Usuario usuario) {
  return !esHashContrasena(usuario.password);
}
