import 'dbhelper.dart';
import '../model/model.dart';

// Repositorio de ingresos: expone el origen de datos de los ingresos.
// La persistencia real se encuentra en la base de datos SQLite (capa DbHelper),
// del usuario con sesion activa.
class IngresoRepository {
  static const String _tabla = 'ingresos';

  // READ: consulta todos los ingresos ordenados por fecha descendente.
  Future<List<Ingreso>> getIngresos() async {
    final List<Map<String, dynamic>> filas =
        await DbHelper().listar(_tabla, orden: 'fecha DESC');
    return filas.map(Ingreso.fromObject).toList();
  }

  // CREATE: inserta un ingreso en la base de datos.
  Future<void> addIngreso(Ingreso ingreso) async {
    await DbHelper().insertar(_tabla, ingreso.toMap());
  }

  // DELETE: elimina un ingreso por su id.
  Future<void> deleteIngreso(int id) async {
    await DbHelper().eliminar(_tabla, id);
  }
}
