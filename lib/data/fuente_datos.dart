// Fuente de datos de la aplicacion.
//
// Contiene el interruptor que define de donde salen los datos que consumen
// los repositorios, mas dos helpers usados por los datos de demostracion.

/// Origen de los datos usado por los repositorios.
class FuenteDatos {
  /// Interruptor global de la fuente de datos.
  ///
  ///  * `true`  -> MODO DEMO (mock): los repositorios devuelven y modifican
  ///               listas de prueba en memoria. NO se toca SQLite.
  ///  * `false` -> MODO REAL: los repositorios leen y escriben en SQLite
  ///               (capa DbHelper) del usuario con sesion activa.
  ///
  /// Arranca en `false`: la aplicacion guarda y lee los datos financieros
  /// en SQLite (persistencia real). Cambiar a `true` activa el modo demo
  /// con datos de ejemplo en memoria.
  static bool usarMock = false;

  /// Devuelve una fecha (YYYY-MM-DD) dentro del MES EN CURSO.
  /// Los datos de demostracion la usan para que los gastos e ingresos de
  /// ejemplo siempre aparezcan en el mes que esta mostrando la interfaz.
  static String fechaDemo(int diaDelMes) {
    final DateTime hoy = DateTime.now();
    final int ultimoDia = DateTime(hoy.year, hoy.month + 1, 0).day;
    final int dia = diaDelMes < 1 ? 1 : (diaDelMes > ultimoDia ? ultimoDia : diaDelMes);
    final String mes = hoy.month.toString().padLeft(2, '0');
    final String diaTexto = dia.toString().padLeft(2, '0');
    return '${hoy.year}-$mes-$diaTexto';
  }

  /// Proximo id disponible para una entidad nueva dentro de una lista mock.
  /// Se calcula con el mayor id existente + 1 (nunca repite id).
  static int proximoId(Iterable<int?> ids) {
    int maximo = 0;
    for (final int? id in ids) {
      if (id != null && id > maximo) {
        maximo = id;
      }
    }
    return maximo + 1;
  }
}
