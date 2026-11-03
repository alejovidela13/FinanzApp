import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  final void Function(BuildContext) onIniciarSesion;
  final void Function(BuildContext) onCrearCuenta;

  const WelcomeScreen({
    super.key,
    required this.onIniciarSesion,
    required this.onCrearCuenta,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 90,
                  color: const Color(0xFF4C68FF),
                ),
                const SizedBox(height: 16),
                const Text(
                  'FinanzApp',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Controla tus gastos, ahorros y metas',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  onPressed: () => onIniciarSesion(context),
                  label: const Text('Iniciar sesión'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => onCrearCuenta(context),
                  label: const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
