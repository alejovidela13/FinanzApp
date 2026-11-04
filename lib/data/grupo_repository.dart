import 'dbhelper.dart';
import 'fuente_datos.dart';
import '../model/model.dart';

// Repositorio de grupos de gastos compartidos.
// Detras puede haber dos origenes de datos: la lista de prueba (mock) o
// SQLite a traves de DbHelper (del usuario con sesion activa), segun
// FuenteDatos.usarMock.
class GrupoRepository {
  static const String _tabla = 'grupos';

  // MOCK: datos de prueba locales en una lista.
  static final List<Grupo> _gruposMock = <Grupo>[
    Grupo.withId(1, 'Asado del finde', 5, 3500, 'asado'),
    Grupo.withId(2, 'Viaje a la costa', 4, -12000, 'viaje'),
    Grupo.withId(3, 'Futbol 5', 10, 0, 'futbol'),
    Grupo.withId(4, 'Cumple de Ana', 8, 2000, 'otro'),
  ];

  // READ: consulta todos los grupos ordenados por nombre.
  Future<List<Grupo>> getGrupos() async {
    if (FuenteDatos.usarMock) {
      return List<Grupo>.of(_gruposMock);
    }
    final List<Map<String, dynamic>> filas =
        await DbHelper().listar(_tabla, orden: 'nombre ASC');
    return filas.map(Grupo.fromObject).toList();
  }

  // CREATE: agrega un grupo y devuelve su id en la base.
  Future<int> addGrupo(Grupo grupo) async {
    if (FuenteDatos.usarMock) {
      grupo.id = FuenteDatos.proximoId(_gruposMock.map((Grupo g) => g.id));
      _gruposMock.add(grupo);
      return grupo.id!;
    }
    return await DbHelper().insertar(_tabla, grupo.toMap());
  }

  // UPDATE: modifica un grupo (por ejemplo, su saldo tras un pago).
  Future<void> updateGrupo(Grupo grupo) async {
    if (FuenteDatos.usarMock) {
      final int i = _gruposMock.indexWhere((Grupo g) => g.id == grupo.id);
      if (i >= 0) {
        _gruposMock[i] = grupo;
      }
      return;
    }
    await DbHelper().actualizar(_tabla, grupo.toMap());
  }

  // DELETE: elimina un grupo por su id.
  Future<void> deleteGrupo(int id) async {
    if (FuenteDatos.usarMock) {
      _gruposMock.removeWhere((Grupo g) => g.id == id);
      return;
    }
    await DbHelper().eliminar(_tabla, id);
  }
}
