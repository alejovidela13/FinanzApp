import 'package:flutter/material.dart';

// Encabezado con degradado azul que comparten el login y el registro.
class CabeceraAuth extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;

  const CabeceraAuth({
    super.key,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF4C68FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withAlpha(45),
            child: Icon(icono, size: 34, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// Tarjeta blanca que contiene los campos del formulario.
class TarjetaAuth extends StatelessWidget {
  final Widget child;

  const TarjetaAuth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Estilo comun de los campos de texto de login y registro.
InputDecoration decoracionAuth({
  required String etiqueta,
  required IconData icono,
  Widget? sufijo,
}) {
  return InputDecoration(
    labelText: etiqueta,
    prefixIcon: Icon(icono),
    suffixIcon: sufijo,
    filled: true,
    fillColor: const Color(0xFFF6F8FC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}
