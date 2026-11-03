import 'dbhelper.dart';
import 'fuente_datos.dart';
import '../model/model.dart';

// Repositorio de metas de ahorro.
// Detras puede haber dos origenes de datos: la lista de prueba (mock) o
// SQLite a traves de DbHelper (del usuario con sesion activa), segun
// FuenteDatos.usarMock.
class MetaAhorroRepository {
  static const String _tabla = 'metas_ahorro';

  // MOCK: datos de prueba locales en una lista.
  static final List<MetaAhorro> _metasMock = <MetaAhorro>[
    MetaAhorro.withId(
        1, 'Vacaciones de verano', 'Viajes', 500000, 175000, FuenteDatos.fechaDemo(28)),
    MetaAhorro.withId(
        2, 'Fondo de emergencia', 'Seguridad', 300000, 300000, FuenteDatos.fechaDemo(30)),
    MetaAhorro.withId(
        3, 'Bicicleta nueva', 'Deportes', 180000, 45000, FuenteDatos.fechaDemo(26)),
  ];

  // READ: consulta todas las metas ordenadas por fecha objetivo.
  Future<List<MetaAhorro>> getMetas() async {
    if (FuenteDatos.usarMock) {
      return List<MetaAhorro>.of(_metasMock);
    }
    final List<Map<String, dynamic>> filas =
        await DbHelper().listar(_tabla, orden: 'fechaObjetivo ASC');
    return filas.map(MetaAhorro.fromObject).toList();
  }

  // CREATE: agrega una meta.
  Future<void> addMeta(MetaAhorro meta) async {
    if (FuenteDatos.usarMock) {
      meta.id = FuenteDatos.proximoId(_metasMock.map((MetaAhorro m) => m.id));
      _metasMock.add(meta);
      return;
    }
    await DbHelper().insertar(_tabla, meta.toMap());
  }

  // UPDATE: modifica una meta (por ejemplo, al depositar ahorro).
  Future<void> updateMeta(MetaAhorro meta) async {
    if (FuenteDatos.usarMock) {
      final int i = _metasMock.indexWhere((MetaAhorro m) => m.id == meta.id);
      if (i >= 0) {
        _metasMock[i] = meta;
      }
      return;
    }
    await DbHelper().actualizar(_tabla, meta.toMap());
  }

  // DELETE: elimina una meta por su id.
  Future<void> deleteMeta(int id) async {
    if (FuenteDatos.usarMock) {
      _metasMock.removeWhere((MetaAhorro m) => m.id == id);
      return;
    }
    await DbHelper().eliminar(_tabla, id);
  }
}
