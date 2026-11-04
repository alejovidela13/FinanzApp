import 'package:flutter/material.dart';
import '../data/contrasena.dart';
import '../data/dbhelper.dart';
import '../model/model.dart';
import '../data/usuario_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    final Usuario? usuario = await UsuarioRepository().getUsuarioPorEmail(email);
    // La contrasena se compara contra el hash guardado; las cuentas viejas
    // (texto plano) tambien son aceptadas hasta su migracion.
    if (usuario == null || !contrasenaCorrecta(usuario, password)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credenciales invalidas')),
      );
      return;
    }

    // Cuenta vieja con contrasena en claro: se reemplaza por su hash.
    await UsuarioRepository().migrarContrasena(usuario, password);

    await DbHelper().setCurrentUser(usuario.id ?? 0);
    // La sesion queda en disco: la app recuerda al usuario al reiniciar.
    await UsuarioRepository().guardarSesion(usuario.id ?? 0);
    if (!mounted) {
      return;
    }
    // Se retorna el id del usuario autenticado; la app recarga sus datos.
    Navigator.of(context).pop(usuario.id ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Iniciar sesion',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo'),
                validator: (value) => (value == null || !value.contains('@')) ? 'Ingresá un correo valido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contrasena'),
                validator: (value) => (value == null || value.isEmpty) ? 'Ingresá tu contrasena' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _iniciarSesion,
                child: const Text('Entrar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
