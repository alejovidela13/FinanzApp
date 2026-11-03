import 'package:sqflite/sqflite.dart';
import 'dbhelper.dart';
import '../model/model.dart';

// Repositorio de gastos: expone el origen de datos de los gastos.
// La persistencia real se encuentra en la base de datos SQLite (capa DbHelper),
// del usuario con sesion activa.
class GastoRepository {
  // READ: consulta todos los gastos ordenados por fecha de expiracion.
  Future<List<Gasto>> getGastos() async {
    final Database db = await DbHelper().db;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT * FROM gastos ORDER BY expiration ASC');
    return result.map(Gasto.fromObject).toList();
  }

  // CREATE: inserta un gasto en la base de datos.
  Future<void> addGasto(Gasto gasto) async {
    final Database db = await DbHelper().db;
    await db.insert('gastos', gasto.toMap());
  }

  // UPDATE: modifica un gasto localizandolo por su id.
  Future<void> updateGasto(Gasto gasto) async {
    final Database db = await DbHelper().db;
    await db.update('gastos', gasto.toMap(), where: 'id = ?', whereArgs: [gasto.id]);
  }

  // DELETE: elimina un gasto por su id.
  Future<void> deleteGasto(int id) async {
    final Database db = await DbHelper().db;
    await db.delete('gastos', where: 'id = ?', whereArgs: [id]);
  }
}
