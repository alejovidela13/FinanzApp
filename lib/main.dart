import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

import 'data/dbhelper.dart';
import 'model/model.dart';
import 'data/usuario_repository.dart';
import 'ui/login_screen.dart';
import 'ui/main_nav_screen.dart';
import 'ui/usuario_screen.dart';
import 'ui/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializacion del factory de SQLite para escritorio (Linux/Windows) o pruebas.
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    databaseFactory = databaseFactoryFfi;
  }

  // Usuario inicial de prueba para la app (cuenta reutilizable).
  // Se busca por email en el registro GLOBAL de cuentas, de modo que funcione
  // aunque la sesion activa apunte a otra base de datos.
  await DbHelper().setCurrentUser(1);
  final Usuario? usuarioPrueba =
      await DbHelper().getUsuarioPorEmail('test@finanzapp.com');
  if (usuarioPrueba == null) {
    final int idPrueba = await UsuarioRepository().crearUsuario(
      nombre: 'Usuario Test',
      email: 'test@finanzapp.com',
      password: '123456',
    );
    await DbHelper().setCurrentUser(idPrueba);
  } else {
    await DbHelper().setCurrentUser(usuarioPrueba.id ?? 1);
  }

  runApp(const FinanzApp());
}

class FinanzApp extends StatefulWidget {
  const FinanzApp({super.key});

  @override
  State<FinanzApp> createState() => _FinanzAppState();
}

class _FinanzAppState extends State<FinanzApp> {
  bool _autenticado = false;

  Future<void> _abrirLogin(BuildContext ctx) async {
    final int? userId = await Navigator.of(ctx).push<int>(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    if (userId != null && mounted) {
      setState(() {
        _autenticado = true;
      });
    }
  }

  Future<void> _abrirRegistro(BuildContext ctx) async {
    final int? userId = await Navigator.of(ctx).push<int>(
      MaterialPageRoute(builder: (context) => const UsuarioScreen()),
    );
    if (userId != null && mounted) {
      setState(() {
        _autenticado = true;
      });
    }
  }

  // Vuelve la aplicacion al flujo de bienvenida (lo usa el perfil).
  void _cerrarSesion() {
    if (mounted) {
      setState(() {
        _autenticado = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanzApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: !_autenticado
          ? WelcomeScreen(
              onIniciarSesion: _abrirLogin,
              onCrearCuenta: _abrirRegistro,
            )
          : MainNavScreen(onCerrarSesion: _cerrarSesion),
    );
  }
}
