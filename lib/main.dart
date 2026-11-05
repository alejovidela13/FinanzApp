import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'dart:io';

import 'data/dbhelper.dart';
import 'model/model.dart';
import 'data/usuario_repository.dart';
import 'ui/login_screen.dart';
import 'ui/main_nav_screen.dart';
import 'ui/onboarding_screen.dart';
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
  final Usuario? usuarioPrueba = await DbHelper().getUsuarioPorEmail(
    'test@finanzapp.com',
  );
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
  bool _cargando = true;
  bool _mostrarIntroduccion = false;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  // Decide la primera pantalla: si hay sesion guardada entra directo; si no,
  // muestra la introduccion (solo la primera vez) y luego la bienvenida.
  Future<void> _iniciar() async {
    final bool vista = await DbHelper().introduccionVista();
    await _restaurarSesion();
    if (mounted) {
      setState(() {
        _cargando = false;
        _mostrarIntroduccion = !vista;
      });
    }
  }

  Future<void> _terminarIntroduccion() async {
    await DbHelper().marcarIntroduccionVista();
    if (mounted) {
      setState(() => _mostrarIntroduccion = false);
    }
  }

  // Si quedo una sesion guardada (login o registro anteriores) y la cuenta
  // sigue existiendo, la app entra directo al inicio sin pedir login.
  Future<void> _restaurarSesion() async {
    final int? userId = await DbHelper().leerSesion();
    if (userId == null) {
      return;
    }
    final Usuario? usuario = await DbHelper().getUser(userId);
    if (usuario == null) {
      // La cuenta fue eliminada: se descarta la sesion guardada.
      await DbHelper().cerrarSesion();
      return;
    }
    await DbHelper().setCurrentUser(userId);
    if (mounted) {
      setState(() => _autenticado = true);
    }
  }

  Future<void> _abrirLogin(BuildContext ctx) async {
    final int? userId = await Navigator.of(
      ctx,
    ).push<int>(MaterialPageRoute(builder: (context) => const LoginScreen()));
    if (userId != null && mounted) {
      setState(() {
        _autenticado = true;
      });
    }
  }

  Future<void> _abrirRegistro(BuildContext ctx) async {
    final int? userId = await Navigator.of(
      ctx,
    ).push<int>(MaterialPageRoute(builder: (context) => const UsuarioScreen()));
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
      theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
      home: _pantallaInicial(),
    );
  }

  Widget _pantallaInicial() {
    // Mientras se decide la pantalla inicial (unos milisegundos) se muestra
    // un fondo vacio: sin animaciones infinitas, para que los tests asienten.
    if (_cargando) {
      return const Scaffold(backgroundColor: Color(0xFFF6F8FC));
    }
    if (_autenticado) {
      return MainNavScreen(onCerrarSesion: _cerrarSesion);
    }
    if (_mostrarIntroduccion) {
      return OnboardingScreen(onTerminar: _terminarIntroduccion);
    }
    return WelcomeScreen(
      onIniciarSesion: _abrirLogin,
      onCrearCuenta: _abrirRegistro,
    );
  }
}
