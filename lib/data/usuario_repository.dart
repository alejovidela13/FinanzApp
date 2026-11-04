import 'contrasena.dart';
import 'dbhelper.dart';
import '../model/model.dart';

// Error lanzado cuando se intenta registrar o cambiar un correo que ya
// pertenece a otra cuenta.
class EmailEnUsoException implements Exception {
  final String email;
  EmailEnUsoException(this.email);

  @override
  String toString() => 'Ya existe una cuenta con el correo $email';
}

// Repositorio de usuarios: expone el origen de datos de los usuarios.
// Por ahora la persistencia real se encuentra en la base de datos SQLite
// (capa DbHelper); una cuenta nueva se resuelve sobre su propia base de datos.
class UsuarioRepository {
  // Crea una cuenta nueva: se le asigna un identificador unico en el registro
  // global y, por lo tanto, una base de datos de gastos vacia (la aplicacion
  // "vuelve de 0"). El id se calcula con MAX(id)+1 sobre TODAS las cuentas,
  // lo que evita el error "UNIQUE constraint failed: usuarios.id".
  //
  // El correo tiene que ser unico y la contrasena se guarda hasheada
  // (nunca en texto plano). Lanza [EmailEnUsoException] si el correo ya
  // esta registrado.
  Future<int> crearUsuario({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final String correo = email.trim();
    if (!await emailDisponible(correo)) {
      throw EmailEnUsoException(correo);
    }

    final int userId = await DbHelper().siguienteIdUsuario();
    final Usuario usuario = Usuario(
      nombre.trim(),
      correo,
      hashContrasena(correo, password),
      userId,
    );
    // Primero se registra la cuenta (base global) y recien despues se cambia
    // la sesion activa a la base de gastos del nuevo usuario.
    final int id = await DbHelper().insertUser(usuario);
    await DbHelper().setCurrentUser(userId);
    return id;
  }

  // Guarda en disco la cuenta con sesion activa para que la aplicacion
  // recuerde al usuario despues de reiniciar (la llama la UI al iniciar
  // sesion o al registrarse, nunca el arranque de la app).
  Future<void> guardarSesion(int userId) async {
    await DbHelper().guardarSesion(userId);
  }

  // Borra la sesion guardada (logout).
  Future<void> cerrarSesion() async {
    await DbHelper().cerrarSesion();
  }

  // READ: obtiene un usuario por su id.
  Future<Usuario?> getUsuario(int id) async {
    return await DbHelper().getUser(id);
  }

  // READ: obtiene un usuario por su email.
  Future<Usuario?> getUsuarioPorEmail(String email) async {
    return await DbHelper().getUsuarioPorEmail(email);
  }

  // READ: retorna todos los usuarios.
  Future<List<Usuario>> getUsuarios() async {
    return await DbHelper().getUsers();
  }

  // Comprueba que un correo no este tomado por otra cuenta.
  // `ignorarId` permite conservar el propio correo al editar el perfil.
  Future<bool> emailDisponible(String email, {int? ignorarId}) async {
    final Usuario? existente = await getUsuarioPorEmail(email);
    if (existente == null) {
      return true;
    }
    return existente.id == ignorarId;
  }

  // UPDATE: modifica los datos de la cuenta con sesion activa (perfil).
  // Si cambia el correo, se verifica que no este en uso por otra cuenta
  // (lanza [EmailEnUsoException]). La contrasena se guarda hasheada.
  Future<void> actualizarUsuario({
    required int id,
    required String nombre,
    required String email,
    required String password,
  }) async {
    final String correo = email.trim();
    if (!await emailDisponible(correo, ignorarId: id)) {
      throw EmailEnUsoException(correo);
    }
    final Usuario usuario = Usuario.withId(
      id,
      nombre.trim(),
      correo,
      // Si no viene contrasena nueva, se conserva la que ya tiene la cuenta
      // (que puede ser un hash de un login anterior).
      password.isEmpty ? await _passwordActual(id) : hashContrasena(correo, password),
    );
    await DbHelper().updateUser(usuario);
  }

  // Devuelve la contrasena guardada (hash) de la cuenta indicada.
  Future<String> _passwordActual(int id) async {
    final Usuario? actual = await getUsuario(id);
    return actual?.password ?? '';
  }

  // Guarda la contrasena de una cuenta vieja (que estaba en texto plano)
  // en su version hasheada. Se llama apenas el login tiene exito.
  Future<void> migrarContrasena(Usuario usuario, String password) async {
    if (usuario.id == null || !requiereMigracion(usuario)) {
      return;
    }
    final Usuario actualizado = Usuario.withId(
      usuario.id,
      usuario.nombre,
      usuario.email,
      hashContrasena(usuario.email, password),
    );
    await DbHelper().updateUser(actualizado);
  }
}
