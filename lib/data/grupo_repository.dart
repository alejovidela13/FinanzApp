import 'dbhelper.dart';
import '../model/model.dart';

// Repositorio de grupos de gastos compartidos.
// La persistencia real se encuentra en la base de datos SQLite (capa DbHelper),
// del usuario con sesion activa.
class GrupoRepository {
  static const String _tabla = 'grupos';

  // READ: consulta todos los grupos ordenados por nombre.
  Future<List<Grupo>> getGrupos() async {
    final List<Map<String, dynamic>> filas =
        await DbHelper().listar(_tabla, orden: 'nombre ASC');
    return filas.map(Grupo.fromObject).toList();
  }

  // CREATE: inserta un grupo en la base de datos.
  Future<void> addGrupo(Grupo grupo) async {
    await DbHelper().insertar(_tabla, grupo.toMap());
  }

  // DELETE: elimina un grupo por su id.
  Future<void> deleteGrupo(int id) async {
    await DbHelper().eliminar(_tabla, id);
  }
}
