import 'dbhelper.dart';
import 'fuente_datos.dart';
import '../model/model.dart';

// Repositorio de ingresos.
// Detras puede haber dos origenes de datos: la lista de prueba (mock) o
// SQLite a traves de DbHelper, segun FuenteDatos.usarMock.
class IngresoRepository {
  static const String _tabla = 'ingresos';

  // MOCK: datos de prueba locales en una lista.
  static final List<Ingreso> _ingresosMock = <Ingreso>[
    Ingreso.withId(1, 'Sueldo', 350000, FuenteDatos.fechaDemo(1)),
    Ingreso.withId(2, 'Trabajo freelance', 80000, FuenteDatos.fechaDemo(12)),
  ];

  // READ: consulta todos los ingresos.
  Future<List<Ingreso>> getIngresos() async {
    if (FuenteDatos.usarMock) {
      return List<Ingreso>.of(_ingresosMock);
    }
    final List<Map<String, dynamic>> filas =
        await DbHelper().listar(_tabla, orden: 'fecha DESC');
    return filas.map(Ingreso.fromObject).toList();
  }

  // CREATE: inserta un ingreso.
  Future<void> addIngreso(Ingreso ingreso) async {
    if (FuenteDatos.usarMock) {
      ingreso.id =
          FuenteDatos.proximoId(_ingresosMock.map((Ingreso i) => i.id));
      _ingresosMock.add(ingreso);
      return;
    }
    await DbHelper().insertar(_tabla, ingreso.toMap());
  }

  // DELETE: elimina un ingreso por su id.
  Future<void> deleteIngreso(int id) async {
    if (FuenteDatos.usarMock) {
      _ingresosMock.removeWhere((Ingreso i) => i.id == id);
      return;
    }
    await DbHelper().eliminar(_tabla, id);
  }
}
