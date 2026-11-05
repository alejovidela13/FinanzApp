import 'package:flutter/material.dart';

import '../data/dbhelper.dart';
import '../model/model.dart';
import '../data/usuario_repository.dart';
import 'login_screen.dart';
import 'usuario_screen.dart';

/// Pantalla de perfil de la cuenta activa.
/// Permite ver los datos, editarlos (se guardan en SQLite) y cerrar sesion
/// para volver a la pantalla de bienvenida.
class ProfileScreen extends StatefulWidget {
  final VoidCallback onCerrarSesion;

  const ProfileScreen({super.key, required this.onCerrarSesion});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Usuario? _usuario;
  bool _cargando = true;
  bool _editando = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Carga desde la base de datos global la cuenta con sesion activa.
  Future<void> _cargarUsuario() async {
    final int? id = DbHelper().currentUserId;
    Usuario? usuario;
    if (id != null) {
      usuario = await UsuarioRepository().getUsuario(id);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _usuario = usuario;
      _cargando = false;
      if (usuario != null) {
        _nombreController.text = usuario.nombre;
        _emailController.text = usuario.email;
        // NUNCA se precarga la contrasena guardada: es un hash y no hay que
        // volver a guardarla como si fuera el texto original.
        _passwordController.text = '';
      }
    });
  }

  // Valida el formulario y persiste los cambios en SQLite.
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final int? id = _usuario?.id ?? DbHelper().currentUserId;
    if (id == null) {
      return;
    }

    setState(() => _guardando = true);
    try {
      await UsuarioRepository().actualizarUsuario(
        id: id,
        nombre: _nombreController.text.trim(),
        email: _emailController.text.trim(),
        // Vacio = no cambiar la contrasena de la cuenta.
        password: _passwordController.text.trim(),
      );
    } on EmailEnUsoException {
      if (!mounted) {
        return;
      }
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese correo ya está en uso')),
      );
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron guardar los datos')),
      );
      return;
    }

    // Se vuelve a leer la cuenta: asi el estado refleja lo que quedo en la
    // base (incluido el hash de la contrasena si se cambio).
    await _cargarUsuario();
    if (!mounted) {
      return;
    }
    setState(() {
      _guardando = false;
      _editando = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos actualizados')),
    );
  }

  // Crea una cuenta nueva desde el perfil. Si se crea, se cierra el perfil
  // para que la pantalla principal recargue los datos de la cuenta activa.
  Future<void> _crearOtraCuenta() async {
    final int? userId = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (context) => const UsuarioScreen()),
    );
    if (userId != null && mounted) {
      Navigator.of(context).pop();
    }
  }

  // Inicia sesion con otra cuenta desde el perfil (mismo criterio que arriba).
  Future<void> _iniciarOtraSesion() async {
    final int? userId = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    if (userId != null && mounted) {
      Navigator.of(context).pop();
    }
  }

  // Cierra el perfil y vuelve a la pantalla de bienvenida.
  // Borra ademas la sesion guardada en disco para que la proxima apertura
  // de la app pida iniciar sesion de nuevo.
  Future<void> _cerrarSesion() async {
    final VoidCallback cerrar = widget.onCerrarSesion;
    await DbHelper().cerrarSesion();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    cerrar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildContenido(),
    );
  }

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_usuario == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No se encontro la cuenta activa.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    final String inicial = _usuario!.nombre.isEmpty
        ? '?'
        : _usuario!.nombre.substring(0, 1).toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera con avatar y datos basicos.
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF4C68FF).withAlpha(30),
                  child: Text(
                    inicial,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C68FF),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _usuario!.nombre,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _usuario!.email,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Formulario de datos (solo lectura o editable).
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _editando ? _buildFormularioEdicion() : _buildSoloLectura(),
          ),
          const SizedBox(height: 20),

          if (_editando) ...[
            ElevatedButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _guardando
                  ? null
                  : () {
                      setState(() => _editando = false);
                      _cargarUsuario();
                    },
              child: const Text('Cancelar'),
            ),
          ] else
            OutlinedButton.icon(
              onPressed: () => setState(() => _editando = true),
              icon: const Icon(Icons.edit),
              label: const Text('Editar datos'),
            ),

          const SizedBox(height: 24),

          // Cuentas: crear una nueva o entrar con otra.
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Cuentas',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _crearOtraCuenta,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Crear otra cuenta'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _iniciarOtraSesion,
            icon: const Icon(Icons.login_outlined),
            label: const Text('Iniciar sesión con otra cuenta'),
          ),
          const SizedBox(height: 24),

          // Cerrar sesion: vuelve al flujo Bienvenida -> Login/Registro.
          OutlinedButton.icon(
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // Vista de solo lectura de los datos de la cuenta.
  Widget _buildSoloLectura() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos de la cuenta',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _datoFila(Icons.person_outline, 'Nombre', _usuario!.nombre),
        _datoFila(Icons.mail_outline, 'Correo', _usuario!.email),
        // Se muestra una cantidad fija de puntos: el largo del hash revelaria
        // informacion y la contrasena real no se puede recuperar.
        _datoFila(
          Icons.lock_outline,
          'Contraseña',
          _usuario!.password.isEmpty ? 'Sin contraseña' : '•' * 8,
        ),
      ],
    );
  }

  Widget _datoFila(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(valor, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Formulario editable con validacion robusta.
  Widget _buildFormularioEdicion() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Editar datos',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Ingresá un nombre' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo',
              border: OutlineInputBorder(),
            ),
            validator: (value) => (value == null || !value.contains('@'))
                ? 'Ingresá un correo valido'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña (opcional)',
              helperText: 'Dejalo vacío para mantener la actual',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return null; // sin cambio de contrasena
              }
              if (value.trim().length < 6) {
                return 'Usá al menos 6 caracteres';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
