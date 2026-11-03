import 'dbhelper.dart';
import '../model/model.dart';

// Repositorio de metas de ahorro.
// La persistencia real se encuentra en la base de datos SQLite (capa DbHelper),
// del usuario con sesion activa.
class MetaAhorroRepository {
  static const String _tabla = 'metas_ahorro';

  // READ: consulta todas las metas ordenadas por fecha objetivo.
  Future<List<MetaAhorro>> getMetas() async {
    final List<Map<String, dynamic>> filas =
        await DbHelper().listar(_tabla, orden: 'fechaObjetivo ASC');
    return filas.map(MetaAhorro.fromObject).toList();
  }

  // CREATE: inserta una meta en la base de datos.
  Future<void> addMeta(MetaAhorro meta) async {
    await DbHelper().insertar(_tabla, meta.toMap());
  }

  // UPDATE: modifica una meta (por ejemplo, al depositar ahorro).
  Future<void> updateMeta(MetaAhorro meta) async {
    await DbHelper().actualizar(_tabla, meta.toMap());
  }

  // DELETE: elimina una meta por su id.
  Future<void> deleteMeta(int id) async {
    await DbHelper().eliminar(_tabla, id);
  }
}
