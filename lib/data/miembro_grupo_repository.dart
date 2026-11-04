import 'dbhelper.dart';
import 'fuente_datos.dart';
import '../model/model.dart';

// Repositorio de los integrantes de un grupo y sus deudas individuales.
// Detras puede haber dos origenes de datos: la lista de prueba (mock) o
// SQLite a traves de DbHelper (del usuario con sesion activa), segun
// FuenteDatos.usarMock.
class MiembroGrupoRepository {
  static const String _tabla = 'grupo_miembros';

  // MOCK: integrantes de prueba en memoria (los grupos del mock arrancan
  // sin deudas individuales cargadas).
  static final List<MiembroGrupo> _miembrosMock = <MiembroGrupo>[];

  // READ: integrantes de un grupo, en el orden en que se cargaron.
  Future<List<MiembroGrupo>> getMiembros(int grupoId) async {
    if (FuenteDatos.usarMock) {
      return _miembrosMock
          .where((MiembroGrupo m) => m.grupoId == grupoId)
          .toList();
    }
    final List<Map<String, dynamic>> filas = await DbHelper().listar(
      _tabla,
      where: 'grupoId = ?',
      args: [grupoId],
      orden: 'id ASC',
    );
    return filas.map(MiembroGrupo.fromObject).toList();
  }

  // CREATE: agrega un integrante y devuelve su id en la base.
  Future<int> addMiembro(MiembroGrupo miembro) async {
    if (FuenteDatos.usarMock) {
      miembro.id = FuenteDatos.proximoId(_miembrosMock.map((MiembroGrupo m) => m.id));
      _miembrosMock.add(miembro);
      return miembro.id!;
    }
    return await DbHelper().insertar(_tabla, miembro.toMap());
  }

  // UPDATE: modifica un integrante (por ejemplo, su deuda).
  Future<void> updateMiembro(MiembroGrupo miembro) async {
    if (FuenteDatos.usarMock) {
      final int i =
          _miembrosMock.indexWhere((MiembroGrupo m) => m.id == miembro.id);
      if (i >= 0) {
        _miembrosMock[i] = miembro;
      }
      return;
    }
    await DbHelper().actualizar(_tabla, miembro.toMap());
  }

  // DELETE: elimina un integrante por su id.
  Future<void> deleteMiembro(int id) async {
    if (FuenteDatos.usarMock) {
      _miembrosMock.removeWhere((MiembroGrupo m) => m.id == id);
      return;
    }
    await DbHelper().eliminar(_tabla, id);
  }
}
