import 'package:sqflite/sqflite.dart';
import 'dbhelper.dart';
import 'fuente_datos.dart';
import '../model/model.dart';

// Repositorio de gastos.
//
// Implementa el patron Repository: es el unico punto por el que la interfaz
// pide gastos. Detras puede haber DOS origenes de datos:
//   * mock  -> lista de prueba en memoria (FuenteDatos.usarMock == true)
//   * real  -> SQLite a traves de DbHelper (FuenteDatos.usarMock == false)
// Las pantallas no cambian: solo llaman a estos metodos.
class GastoRepository {
  // -------------------------------------------------------------------
  // MOCK: datos de prueba locales en una lista (se borran al cerrar la app).
  // -------------------------------------------------------------------
  static final List<Gasto> _gastosMock = <Gasto>[
    Gasto.withId(1, 'Alquiler', 1500, 'Servicios', FuenteDatos.fechaDemo(1), 1, 1, 1),
    Gasto.withId(2, 'Supermercado', 820, 'Comida', FuenteDatos.fechaDemo(8), 1, 1, 1),
    Gasto.withId(3, 'Nafta', 310, 'Transporte', FuenteDatos.fechaDemo(14), 1, 1, 1),
    Gasto.withId(4, 'Entradas de cine', 240, 'Entretenimiento', FuenteDatos.fechaDemo(22), 1, 1, 1),
  ];

  // READ: consulta todos los gastos ordenados por fecha de expiracion.
  Future<List<Gasto>> getGastos() async {
    if (FuenteDatos.usarMock) {
      return List<Gasto>.of(_gastosMock);
    }
    final Database db = await DbHelper().db;
    final List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM gastos ORDER BY expiration ASC');
    return result.map(Gasto.fromObject).toList();
  }

  // CREATE: agrega un gasto.
  Future<void> addGasto(Gasto gasto) async {
    if (FuenteDatos.usarMock) {
      gasto.id = FuenteDatos.proximoId(_gastosMock.map((Gasto g) => g.id));
      _gastosMock.add(gasto);
      return;
    }
    final Database db = await DbHelper().db;
    await db.insert('gastos', gasto.toMap());
  }

  // UPDATE: modifica un gasto localizandolo por su id.
  Future<void> updateGasto(Gasto gasto) async {
    if (FuenteDatos.usarMock) {
      final int i = _gastosMock.indexWhere((Gasto g) => g.id == gasto.id);
      if (i >= 0) {
        _gastosMock[i] = gasto;
      }
      return;
    }
    final Database db = await DbHelper().db;
    await db.update('gastos', gasto.toMap(),
        where: 'id = ?', whereArgs: [gasto.id]);
  }

  // DELETE: elimina un gasto por su id.
  Future<void> deleteGasto(int id) async {
    if (FuenteDatos.usarMock) {
      _gastosMock.removeWhere((Gasto g) => g.id == id);
      return;
    }
    final Database db = await DbHelper().db;
    await db.delete('gastos', where: 'id = ?', whereArgs: [id]);
  }
}
