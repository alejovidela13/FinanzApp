import 'dbhelper.dart';
import '../model/model.dart';

// Repositorio de usuarios: expone el origen de datos de los usuarios.
// Por ahora la persistencia real se encuentra en la base de datos SQLite
// (capa DbHelper); una cuenta nueva se resuelve sobre su propia base de datos.
class UsuarioRepository {
  // Crea una cuenta nueva: se le asigna un identificador unico en el registro
  // global y, por lo tanto, una base de datos de gastos vacia (la aplicacion
  // "vuelve de 0"). El id se calcula con MAX(id)+1 sobre TODAS las cuentas,
  // lo que evita el error "UNIQUE constraint failed: usuarios.id".
  Future<int> crearUsuario({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final int userId = await DbHelper().siguienteIdUsuario();
    final Usuario usuario = Usuario(nombre, email, password, userId);
    // Primero se registra la cuenta (base global) y recien despues se cambia
    // la sesion activa a la base de gastos del nuevo usuario.
    final int id = await DbHelper().insertUser(usuario);
    await DbHelper().setCurrentUser(userId);
    return id;
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

  // UPDATE: modifica los datos de la cuenta con sesion activa (perfil).
  Future<void> actualizarUsuario({
    required int id,
    required String nombre,
    required String email,
    required String password,
  }) async {
    final Usuario usuario = Usuario.withId(id, nombre, email, password);
    await DbHelper().updateUser(usuario);
  }
}
