import 'package:flutter/material.dart';
import '../data/contrasena.dart';
import '../data/dbhelper.dart';
import '../model/model.dart';
import '../data/usuario_repository.dart';
import 'auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _ocultarPassword = true;

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
        const SnackBar(content: Text('Credenciales inválidas')),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CabeceraAuth(
              icono: Icons.lock_open_rounded,
              titulo: 'Iniciar sesión',
              subtitulo: 'Entrá para ver tus finanzas',
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: TarjetaAuth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: decoracionAuth(
                          etiqueta: 'Correo',
                          icono: Icons.mail_outline,
                        ),
                        validator: (value) => (value == null || !value.contains('@'))
                            ? 'Ingresá un correo válido'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _ocultarPassword,
                        decoration: decoracionAuth(
                          etiqueta: 'Contraseña',
                          icono: Icons.lock_outline,
                          sufijo: IconButton(
                            icon: Icon(_ocultarPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _ocultarPassword = !_ocultarPassword),
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Ingresá tu contraseña'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: const Color(0xFF4C68FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _iniciarSesion,
                        child: const Text(
                          'Entrar',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
