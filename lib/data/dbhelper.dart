import 'dart:io';

import 'package:sqflite/sqflite.dart';
import '../model/model.dart';

// Capa de persistencia local (SQLite) encapsulada.
// Patron Singleton: un unico punto de acceso a la base de datos.
//
// Se manejan DOS bases de datos:
//  * `finanzapp_usuarios.db` -> registro GLOBAL de cuentas. Al estar fuera de
//    las bases individuales, el login funciona desde cualquier sesion y los
//    id de usuario son unicos en toda la aplicacion.
//  * `finanzapp_<id>.db`     -> gastos EXCLUSIVOS de cada usuario. Una cuenta
//    nueva abre una base vacia (la aplicacion "vuelve de 0").
class DbHelper {
  // 1. Instancia interna privada y estatica unica.
  static final DbHelper _dbHelper = DbHelper._internal();

  // 2. Constructor privado para evitar instanciacion externa directa.
  DbHelper._internal();

  // 3. Factory constructor que retorna siempre la misma instancia unica.
  factory DbHelper() {
    return _dbHelper;
  }

  // Variable de referencia a la conexion de los gastos del usuario actual.
  static Database? _db;

  // Identificador del usuario propietario de la base de datos actual.
  static int? _dbUserId;

  // Conexion al registro global de usuarios (compartido por todas las cuentas).
  static Database? _dbUsuarios;

  // Evita reintentar la migracion de cuentas en cada acceso.
  static bool _migracionUsuariosHecha = false;

  // Usuario con sesion activa en la aplicacion.
  static int? _currentUserId;

  int? get currentUserId => _currentUserId;

  // Establece el usuario con sesion activa; la app usara su propia base de datos.
  Future<void> setCurrentUser(int userId) async {
    _currentUserId = userId;
  }

  // Crea (si no existen) las tablas del registro global de cuentas.
  // Se ejecuta en cada apertura: las bases creadas por versiones anteriores
  // de la aplicacion ya tienen el archivo y no vuelven a pasar por onCreate.
  Future<void> _crearTablaUsuarios(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS usuarios ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'nombre TEXT, '
        'email TEXT, '
        'password TEXT);');
  }

  Future<String> _rutaDe(String nombreArchivo) async {
    final String databasesPath = await getDatabasesPath();
    return '$databasesPath/$nombreArchivo';
  }

  // Base de datos global de cuentas (usuarios).
  Future<Database> get dbUsuarios async {
    if (_dbUsuarios == null) {
      final String ruta = await _rutaDe('finanzapp_usuarios.db');
      _dbUsuarios = await openDatabase(
        ruta,
        version: 1,
        onCreate: (Database db, int version) => _crearTablaUsuarios(db),
        onOpen: _crearTablaUsuarios,
      );
      await _migrarCuentasExistentes(_dbUsuarios!);
    }
    return _dbUsuarios!;
  }

  // Migracion unica: trae a la tabla global las cuentas que quedaron guardadas
  // en las bases individuales de versiones anteriores de la aplicacion.
  Future<void> _migrarCuentasExistentes(Database global) async {
    if (_migracionUsuariosHecha) {
      return;
    }
    _migracionUsuariosHecha = true;
    try {
      final String directorio = await getDatabasesPath();
      final List<FileSystemEntity> archivos =
          Directory(directorio).listSync(followLinks: false);
      for (final FileSystemEntity archivo in archivos) {
        if (archivo is! File) {
          continue;
        }
        final String nombre = archivo.uri.pathSegments.last;
        if (!nombre.startsWith('finanzapp_') || !nombre.endsWith('.db')) {
          continue;
        }
        if (nombre == 'finanzapp_usuarios.db') {
          continue;
        }
        // No se reabre la base que esta en uso en este momento.
        if (_db != null && nombre == 'finanzapp_$_dbUserId.db') {
          continue;
        }
        try {
          final Database origen = await openDatabase(archivo.path, readOnly: true);
          final List<Map<String, dynamic>> filas = await origen.query('usuarios');
          for (final Map<String, dynamic> fila in filas) {
            await global.insert(
              'usuarios',
              fila,
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
          await origen.close();
        } catch (_) {
          // Base sin tabla de usuarios u otro problema: se ignora a proposito.
        }
      }
    } catch (_) {
      // Si el directorio no se puede listar, la aplicacion sigue normalmente.
    }
  }

  // Devuelve el proximo id de usuario disponible en el registro global.
  // Evita el error "UNIQUE constraint failed: usuarios.id" que provocaba el
  // calculo anterior (id del usuario actual + 1).
  Future<int> siguienteIdUsuario() async {
    final Database base = await dbUsuarios;
    final List<Map<String, dynamic>> filas =
        await base.rawQuery('SELECT MAX(id) AS maxId FROM usuarios');
    final int? maxId = (filas.first['maxId'] as num?)?.toInt();
    return (maxId ?? 0) + 1;
  }

  // Crea (si no existen) todas las tablas de la base del usuario.
  // Se ejecuta en cada apertura, no solo al crear el archivo: una cuenta
  // existente tiene su base desde antes y necesita las tablas nuevas.
  Future<void> _crearTablasGastos(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS gastos ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'concepto TEXT, '
        'monto REAL, '
        'categoria TEXT, '
        'expiration TEXT, '
        'fqYear INTEGER, '
        'fqHalfYear INTEGER, '
        'fqMonth INTEGER);');
    await db.execute('CREATE TABLE IF NOT EXISTS ingresos ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'concepto TEXT, '
        'monto REAL, '
        'fecha TEXT);');
    await db.execute('CREATE TABLE IF NOT EXISTS metas_ahorro ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'titulo TEXT, '
        'categoria TEXT, '
        'montoObjetivo REAL, '
        'montoAhorrado REAL, '
        'fechaObjetivo TEXT);');
    await db.execute('CREATE TABLE IF NOT EXISTS grupos ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'nombre TEXT, '
        'integrantes INTEGER, '
        'saldo INTEGER, '
        'icono TEXT);');
    await db.execute('CREATE TABLE IF NOT EXISTS servicios_hogar ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'titulo TEXT, '
        'detalle TEXT, '
        'monto REAL, '
        'pagado INTEGER);');
  }

  // Obtiene (y cachea) la conexion a la base de datos del usuario actual.
  // Cada cuenta de usuario tiene su propia base de datos: una cuenta nueva
  // arranca con datos vacios (la aplicacion viene de 0).
  Future<Database> get db async {
    final int userId = _currentUserId ?? 0;
    if (_db == null || _dbUserId != userId) {
      final Database? anterior = _db;
      _db = null;
      _dbUserId = userId;
      final String databaseName = 'finanzapp_$userId.db';
      final String ruta = await _rutaDe(databaseName);
      _db = await openDatabase(
        ruta,
        version: 1,
        onCreate: (Database db, int version) => _crearTablasGastos(db),
        onOpen: _crearTablasGastos,
      );
      await anterior?.close();
    }
    return _db!;
  }

  // ---------------------------------------------------------------------
  // CRUD generico sobre la base del usuario con sesion activa.
  // Lo usan los repositorios de las entidades nuevas para no repetir codigo.
  // ---------------------------------------------------------------------

  // CREATE: inserta una fila en la tabla indicada.
  Future<int> insertar(String tabla, Map<String, dynamic> fila) async {
    final Database db = await this.db;
    return await db.insert(tabla, fila);
  }

  // READ: devuelve todas las filas de la tabla, ordenadas opcionalmente.
  Future<List<Map<String, dynamic>>> listar(String tabla, {String? orden}) async {
    final Database db = await this.db;
    return await db.query(tabla, orderBy: orden);
  }

  // UPDATE: modifica la fila localizada por su ID.
  Future<int> actualizar(String tabla, Map<String, dynamic> fila) async {
    final Database db = await this.db;
    return await db.update(tabla, fila, where: 'id = ?', whereArgs: [fila['id']]);
  }

  // DELETE: elimina la fila localizada por su ID.
  Future<int> eliminar(String tabla, int id) async {
    final Database db = await this.db;
    return await db.delete(tabla, where: 'id = ?', whereArgs: [id]);
  }

  // CREATE: inserta un gasto serializado en la base de datos.
  Future<int> insertDoc(Gasto doc) async {
    final Database db = await this.db;
    final int id = await db.insert('gastos', doc.toMap());
    return id;
  }

  // READ: consulta todos los registros y los retorna como una lista de mapas.
  Future<List<Map<String, dynamic>>> getDocs() async {
    final Database db = await this.db;
    final List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM gastos ORDER BY expiration ASC');
    return result;
  }

  // UPDATE: modifica un registro localizandolo por su ID.
  Future<int> updateDoc(Gasto doc) async {
    final Database db = await this.db;
    final int result =
        await db.update('gastos', doc.toMap(), where: 'id = ?', whereArgs: [doc.id]);
    return result;
  }

  // DELETE: trunca la tabla local para el reseteo de la aplicacion.
  Future<int> deleteRows() async {
    final Database db = await this.db;
    final int result = await db.delete('gastos');
    return result;
  }

  // CREATE: inserta una cuenta en el registro GLOBAL de usuarios.
  Future<int> insertUser(Usuario usuario) async {
    final Database base = await dbUsuarios;
    final int id = await base.insert('usuarios', usuario.toMap());
    return id;
  }

  // READ: obtiene un usuario por su id.
  Future<Usuario?> getUser(int id) async {
    final Database base = await dbUsuarios;
    final List<Map<String, dynamic>> filas =
        await base.query('usuarios', where: 'id = ?', whereArgs: [id]);
    if (filas.isEmpty) {
      return null;
    }
    return Usuario.fromObject(filas.first);
  }

  // READ: obtiene un usuario por su email (funciona desde cualquier sesion).
  Future<Usuario?> getUsuarioPorEmail(String email) async {
    final Database base = await dbUsuarios;
    final List<Map<String, dynamic>> filas =
        await base.query('usuarios', where: 'email = ?', whereArgs: [email]);
    if (filas.isEmpty) {
      return null;
    }
    return Usuario.fromObject(filas.first);
  }

  // READ: retorna todos los usuarios.
  Future<List<Usuario>> getUsers() async {
    final Database base = await dbUsuarios;
    final List<Map<String, dynamic>> filas = await base.query('usuarios');
    return filas.map(Usuario.fromObject).toList();
  }

  // UPDATE: modifica los datos de una cuenta en el registro global.
  Future<int> updateUser(Usuario usuario) async {
    final Database base = await dbUsuarios;
    return await base.update(
      'usuarios',
      usuario.toMap(),
      where: 'id = ?',
      whereArgs: [usuario.id],
    );
  }
}
