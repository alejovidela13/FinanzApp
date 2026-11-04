// Test de REGRESION: la migracion de cuentas.
//
// Al abrir la base global, la app recorre las bases individuales de las
// cuentas existentes y las abre en modo SOLO LECTURA para leer su tabla
// vieja "usuarios". Si esa conexion quedara cacheada (singleInstance), la
// base de la cuenta con sesion activa se reabriria en solo lectura y
// TODOS sus escrituras fallarian con "Database readonly".
//
// Se usa un directorio PROPIO porque flutter test ejecuta los archivos
// de test en paralelo.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_application_1/data/dbhelper.dart';
import 'package:flutter_application_1/data/fuente_datos.dart';
import 'package:flutter_application_1/data/gasto_repository.dart';
import 'package:flutter_application_1/data/usuario_repository.dart';
import 'package:flutter_application_1/model/model.dart';

final String _dirTest =
    '${Directory.systemTemp.path}${Platform.pathSeparator}finanzapp_test_dbs_migracion';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    FuenteDatos.usarMock = false;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    final Directory dir = Directory(_dirTest);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    dir.createSync(recursive: true);
    await databaseFactory.setDatabasesPath(dir.path);
  });

  setUp(() async {
    await DbHelper().cerrarSesion();
  });

  test(
    'La migracion de cuentas no deja la base del usuario en solo lectura',
    () async {
      // Base existente de una cuenta, tal como la crea la version actual
      // de la app: NO tiene tabla "usuarios" (por eso la lectura de la
      // migracion falla y esa conexion es la que hay que liberar).
      final String ruta = '$_dirTest/finanzapp_79.db';
      final Database creada = await databaseFactory.openDatabase(ruta);
      await creada.execute('CREATE TABLE gastos ('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'concepto TEXT, monto REAL, categoria TEXT, '
          'expiration TEXT, fqYear INTEGER, fqHalfYear INTEGER, '
          'fqMonth INTEGER);');
      await creada.close();

      // Abrir la base global dispara la migracion: recorre todas las
      // bases del directorio (incluida la del usuario 79, que todavía
      // no tiene sesion activa).
      expect(await UsuarioRepository().getUsuarios(), isEmpty);

      // Al entrar a la cuenta, la base tiene que permitir escrituras.
      await DbHelper().setCurrentUser(79);
      await GastoRepository().addGasto(
        Gasto('Prueba', 100, 'General', '2026-11-04', 0, 0, 0),
      );

      expect(
        await GastoRepository().getGastos(),
        hasLength(1),
        reason: 'La migracion dejo la base del usuario en solo lectura',
      );
    },
  );
}
