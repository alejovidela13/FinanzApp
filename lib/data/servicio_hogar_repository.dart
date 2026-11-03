import 'dbhelper.dart';
import '../model/model.dart';

// Repositorio de servicios y gastos fijos del hogar.
// La persistencia real se encuentra en la base de datos SQLite (capa DbHelper),
// del usuario con sesion activa.
class ServicioHogarRepository {
  static const String _tabla = 'servicios_hogar';

  // READ: consulta todos los servicios ordenados por titulo.
  Future<List<ServicioHogar>> getServicios() async {
    final List<Map<String, dynamic>> filas =
        await DbHelper().listar(_tabla, orden: 'titulo ASC');
    return filas.map(ServicioHogar.fromObject).toList();
  }

  // CREATE: inserta un servicio en la base de datos.
  Future<void> addServicio(ServicioHogar servicio) async {
    await DbHelper().insertar(_tabla, servicio.toMap());
  }

  // UPDATE: modifica un servicio (por ejemplo, para marcarlo como pagado).
  Future<void> updateServicio(ServicioHogar servicio) async {
    await DbHelper().actualizar(_tabla, servicio.toMap());
  }

  // DELETE: elimina un servicio por su id.
  Future<void> deleteServicio(int id) async {
    await DbHelper().eliminar(_tabla, id);
  }
}
