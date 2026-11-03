import 'dbhelper.dart';
import 'fuente_datos.dart';
import '../model/model.dart';

// Repositorio de servicios y gastos fijos del hogar.
// Detras puede haber dos origenes de datos: la lista de prueba (mock) o
// SQLite a traves de DbHelper (del usuario con sesion activa), segun
// FuenteDatos.usarMock.
class ServicioHogarRepository {
  static const String _tabla = 'servicios_hogar';

  // MOCK: datos de prueba locales en una lista.
  static final List<ServicioHogar> _serviciosMock = <ServicioHogar>[
    ServicioHogar.withId(1, 'Luz (Edemsa)', 'Vence el 22', 18500, 1),
    ServicioHogar.withId(2, 'Agua', 'Vence el 28', 6200, 0),
    ServicioHogar.withId(3, 'Internet', 'Vence el 15', 14900, 0),
    ServicioHogar.withId(4, 'Alquiler', 'Vence el 5', 250000, 1),
  ];

  // READ: consulta todos los servicios ordenados por titulo.
  Future<List<ServicioHogar>> getServicios() async {
    if (FuenteDatos.usarMock) {
      return List<ServicioHogar>.of(_serviciosMock);
    }
    final List<Map<String, dynamic>> filas =
        await DbHelper().listar(_tabla, orden: 'titulo ASC');
    return filas.map(ServicioHogar.fromObject).toList();
  }

  // CREATE: agrega un servicio.
  Future<void> addServicio(ServicioHogar servicio) async {
    if (FuenteDatos.usarMock) {
      servicio.id = FuenteDatos.proximoId(
          _serviciosMock.map((ServicioHogar s) => s.id));
      _serviciosMock.add(servicio);
      return;
    }
    await DbHelper().insertar(_tabla, servicio.toMap());
  }

  // UPDATE: modifica un servicio (por ejemplo, para marcarlo como pagado).
  Future<void> updateServicio(ServicioHogar servicio) async {
    if (FuenteDatos.usarMock) {
      final int i =
          _serviciosMock.indexWhere((ServicioHogar s) => s.id == servicio.id);
      if (i >= 0) {
        _serviciosMock[i] = servicio;
      }
      return;
    }
    await DbHelper().actualizar(_tabla, servicio.toMap());
  }

  // DELETE: elimina un servicio por su id.
  Future<void> deleteServicio(int id) async {
    if (FuenteDatos.usarMock) {
      _serviciosMock.removeWhere((ServicioHogar s) => s.id == id);
      return;
    }
    await DbHelper().eliminar(_tabla, id);
  }
}
