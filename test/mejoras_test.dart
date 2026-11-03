// Tests de las mejoras del proyecto FinanzApp:
//   1. Una cuenta nueva arranca con el menu totalmente vacio.
//   2. El boton de perfil funciona: ver datos, editarlos y cerrar sesion.
//   3. Los gastos/ingresos y las entidades nuevas (metas, servicios, grupos)
//      se guardan de verdad en SQLite y se reflejan en la interfaz.
//
// Se usa SQLite real (FFI, en el mismo proceso) sobre un directorio PROPIO:
// flutter test ejecuta los archivos de test en paralelo, asi que no se puede
// compartir la carpeta con widget_test.dart.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/data/dbhelper.dart';
import 'package:flutter_application_1/data/gasto_repository.dart';
import 'package:flutter_application_1/data/grupo_repository.dart';
import 'package:flutter_application_1/data/ingreso_repository.dart';
import 'package:flutter_application_1/data/meta_ahorro_repository.dart';
import 'package:flutter_application_1/model/model.dart';
import 'package:flutter_application_1/data/servicio_hogar_repository.dart';
import 'package:flutter_application_1/data/usuario_repository.dart';

// Ruta aislada para las bases de datos de estos tests.
const String _dirTest = '/tmp/opencode/finanzapp_test_dbs_mejoras';

// Las operaciones de SQLite hacen E/S real (abrir archivos, escribir), por lo
// que NO alcanza con pumpAndSettle: hay que dar vueltas al event loop real del
// sistema y recien despues redibujar la UI.
Future<void> esperarBD(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

// Abre la pantalla de bienvenida y crea una cuenta nueva, quedando en el Inicio.
Future<void> crearCuenta(
  WidgetTester tester, {
  required String nombre,
  required String email,
}) async {
  await tester.pumpWidget(const FinanzApp());
  await tester.pumpAndSettle();
  await esperarBD(tester);

  await tester.tap(find.widgetWithText(OutlinedButton, 'Crear cuenta'));
  await tester.pumpAndSettle();
  await esperarBD(tester);

  await tester.enterText(find.byType(TextFormField).at(0), nombre);
  await tester.enterText(find.byType(TextFormField).at(1), email);
  await tester.enterText(find.byType(TextFormField).at(2), '123456');

  await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
  await tester.pumpAndSettle();
  await esperarBD(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // SQLite corriendo en el mismo proceso: evita hilos/excepciones que
    // compliquen el control de tiempo de los tests.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;

    // Se arranca siempre desde cero para que los resultados sean deterministas.
    final Directory dir = Directory(_dirTest);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    dir.createSync(recursive: true);
    await databaseFactory.setDatabasesPath(dir.path);
  });

  testWidgets(
    'Cuenta nueva: el menu arranca vacio en todas las pantallas',
    (WidgetTester tester) async {
      await crearCuenta(tester, nombre: 'Carla Ruiz', email: 'carla@test.com');

      // ---------------------------------------------------------------
      // INICIO: sin gastos, sin ingresos y todas las tarjetas en $0.
      // ---------------------------------------------------------------
      expect(find.text('Aun no hay gastos registrados.'), findsOneWidget);
      expect(find.text('Sin gastos registrados este mes'), findsOneWidget);
      expect(find.text('Sin gastos para mostrar'), findsOneWidget);
      expect(find.text('Total \$0 • 0 registro(s)'), findsOneWidget);
      expect(find.text('\$0'), findsWidgets);

      // ---------------------------------------------------------------
      // MES: sin movimientos en el periodo.
      // ---------------------------------------------------------------
      await tester.tap(find.text('Mes'));
      await tester.pumpAndSettle();
      await esperarBD(tester);
      expect(find.text('Sin gastos en este período.'), findsOneWidget);
      expect(find.text('Ingresos: \$0'), findsOneWidget);
      expect(find.text('Balance: \$0'), findsOneWidget);

      // ---------------------------------------------------------------
      // HOGAR: sin servicios cargados.
      // ---------------------------------------------------------------
      await tester.tap(find.text('Hogar'));
      await tester.pumpAndSettle();
      await esperarBD(tester);
      expect(
        find.text('Aún no hay servicios cargados. Agregá uno con el botón de arriba.'),
        findsOneWidget,
      );
      expect(find.text('Total Servicios y Hogar'), findsOneWidget);
      expect(find.text('\$0'), findsWidgets);

      // ---------------------------------------------------------------
      // GRUPO: sin grupos creados.
      // ---------------------------------------------------------------
      await tester.tap(find.text('Grupo'));
      await tester.pumpAndSettle();
      await esperarBD(tester);
      expect(
        find.text('Aún no tenés grupos. Creá uno con el botón de arriba.'),
        findsOneWidget,
      );
      expect(find.text('Sin actividad para mostrar.'), findsOneWidget);

      // ---------------------------------------------------------------
      // AHORRO: sin metas creadas.
      // ---------------------------------------------------------------
      await tester.tap(find.text('Ahorro'));
      await tester.pumpAndSettle();
      await esperarBD(tester);
      expect(
        find.text('Aún no tenés metas de ahorro. Creá una para empezar.'),
        findsOneWidget,
      );
      expect(find.text('Total acumulado en metas'), findsOneWidget);
      expect(find.text('\$0'), findsOneWidget);
    },
  );

  testWidgets(
    'Perfil: muestra los datos, permite editarlos y cerrar sesion',
    (WidgetTester tester) async {
      await crearCuenta(tester, nombre: 'Diego Sosa', email: 'diego@test.com');

      // ---------------------------------------------------------------
      // 1. EL BOTON DE PERFIL ABRE LA PANTALLA CON LOS DATOS DE LA CUENTA
      // ---------------------------------------------------------------
      await tester.tap(find.text('😊'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      expect(find.text('Mi Perfil'), findsOneWidget);
      expect(find.text('Datos de la cuenta'), findsOneWidget);
      // El nombre y el correo aparecen en la cabecera y en los datos.
      expect(find.text('Diego Sosa'), findsWidgets);
      expect(find.text('diego@test.com'), findsWidgets);
      expect(find.text('Editar datos'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);

      // ---------------------------------------------------------------
      // 2. SE EDITA EL NOMBRE Y SE PERSISTE EN SQLITE
      // ---------------------------------------------------------------
      await tester.tap(find.widgetWithText(OutlinedButton, 'Editar datos'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Diego Modificado');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar cambios'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      // Se deja pasar el snackbar de confirmacion: si no, tapa los botones
      // que quedan al pie de la pantalla.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // La cabecera refleja el cambio inmediatamente (cabecera + dato).
      expect(find.text('Diego Modificado'), findsWidgets);

      // Ademas el cambio quedo grabado en la base de datos global.
      final int? id = DbHelper().currentUserId;
      expect(id, isNotNull);
      final Usuario? guardado =
          await tester.runAsync<Usuario?>(
              () => UsuarioRepository().getUsuario(id!));
      expect(guardado, isNotNull);
      expect(guardado!.nombre, 'Diego Modificado');

      // ---------------------------------------------------------------
      // 3. CERRAR SESION VUELVE A LA BIENVENIDA
      // ---------------------------------------------------------------
      // El boton queda al fondo de la pantalla: hay que asegurar que este visible.
      await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      expect(find.text('FinanzApp'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Crear cuenta'), findsOneWidget);
      expect(find.text('Mi Perfil'), findsNothing);
    },
  );

  testWidgets(
    'Ingresos y metas de ahorro se guardan en SQLite',
    (WidgetTester tester) async {
      await crearCuenta(tester, nombre: 'Elena Paz', email: 'elena@test.com');

      // ---------------------------------------------------------------
      // 1. ALTA DE UN INGRESO DESDE EL INICIO
      // ---------------------------------------------------------------
      await tester.tap(find.widgetWithText(OutlinedButton, 'Agregar ingreso'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Sueldo');
      await tester.enterText(find.byType(TextFormField).at(1), '50000');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      // La tarjeta de Ingresos del inicio se actualiza con el valor real.
      expect(find.text('\$50000'), findsOneWidget);

      final List<Ingreso> ingresos = await tester
              .runAsync<List<Ingreso>>(() => IngresoRepository().getIngresos()) ??
          <Ingreso>[];
      expect(ingresos, hasLength(1));
      expect(ingresos.first.concepto, 'Sueldo');
      expect(ingresos.first.monto, 50000);

      // ---------------------------------------------------------------
      // 2. ALTA DE UNA META DE AHORRO
      // ---------------------------------------------------------------
      await tester.tap(find.text('Ahorro'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Nueva meta'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Vacaciones');
      await tester.enterText(find.byType(TextFormField).at(1), '20000');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear meta'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      expect(find.text('Vacaciones'), findsOneWidget);

      final List<MetaAhorro> metas = await tester
              .runAsync<List<MetaAhorro>>(() => MetaAhorroRepository().getMetas()) ??
          <MetaAhorro>[];
      expect(metas, hasLength(1));
      expect(metas.first.titulo, 'Vacaciones');
      expect(metas.first.montoObjetivo, 20000);
      expect(metas.first.montoAhorrado, 0);

      // ---------------------------------------------------------------
      // 3. DEPOSITAR AHORRO ACTUALIZA LA META EN LA BASE
      // ---------------------------------------------------------------
      await tester.ensureVisible(find.byTooltip('Acciones de la meta'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Acciones de la meta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Depositar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), '5000');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Depositar'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      expect(find.text('Ahorrado: \$5000'), findsOneWidget);
      expect(find.text('25%'), findsWidgets);

      final List<MetaAhorro> metasActualizadas = await tester
              .runAsync<List<MetaAhorro>>(() => MetaAhorroRepository().getMetas()) ??
          <MetaAhorro>[];
      expect(metasActualizadas.first.montoAhorrado, 5000);
    },
  );

  testWidgets(
    'Servicios del hogar y grupos se guardan en SQLite',
    (WidgetTester tester) async {
      await crearCuenta(tester, nombre: 'Federico Luna', email: 'fede@test.com');

      // ---------------------------------------------------------------
      // 1. ALTA DE UN SERVICIO DEL HOGAR
      // ---------------------------------------------------------------
      await tester.tap(find.text('Hogar'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      await tester.tap(find.byTooltip('Nuevo servicio'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Luz');
      await tester.enterText(find.byType(TextFormField).at(1), 'Vence el 22');
      await tester.enterText(find.byType(TextFormField).at(2), '8500');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      expect(find.text('Luz'), findsOneWidget);
      expect(find.text('\$8500'), findsWidgets);

      List<ServicioHogar> servicios = await tester
              .runAsync<List<ServicioHogar>>(
                  () => ServicioHogarRepository().getServicios()) ??
          <ServicioHogar>[];
      expect(servicios, hasLength(1));
      expect(servicios.first.monto, 8500);
      expect(servicios.first.pagado, 0);

      // ---------------------------------------------------------------
      // 2. MARCAR COMO PAGADO SE REFLEJA EN SQLITE
      // ---------------------------------------------------------------
      await tester.tap(find.byTooltip('Marcar como pagado'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      servicios = await tester
              .runAsync<List<ServicioHogar>>(
                  () => ServicioHogarRepository().getServicios()) ??
          <ServicioHogar>[];
      expect(servicios.first.pagado, 1);

      // ---------------------------------------------------------------
      // 3. EL RESUMEN SUMA LOS SERVICIOS REALES
      // ---------------------------------------------------------------
      await tester.tap(find.byTooltip('Nuevo servicio'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Internet');
      await tester.enterText(find.byType(TextFormField).at(2), '6000');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      expect(find.text('\$14500'), findsOneWidget); // total del resumen
      // Pagado y pendiente aparecen tanto en el resumen como en cada item.
      expect(find.text('\$8500'), findsWidgets);
      expect(find.text('\$6000'), findsWidgets);

      // ---------------------------------------------------------------
      // 4. ALTA DE UN GRUPO
      // ---------------------------------------------------------------
      await tester.tap(find.text('Grupo'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      await tester.tap(find.byTooltip('Nuevo grupo'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Asado');
      await tester.enterText(find.byType(TextFormField).at(1), '4');
      await tester.enterText(find.byType(TextFormField).at(2), '3000');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear grupo'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      expect(find.text('Asado'), findsOneWidget);
      expect(find.text('4 integrantes'), findsOneWidget);
      expect(find.text('Te deben \$3000'), findsOneWidget);

      final List<Grupo> grupos = await tester
              .runAsync<List<Grupo>>(() => GrupoRepository().getGrupos()) ??
          <Grupo>[];
      expect(grupos, hasLength(1));
      expect(grupos.first.nombre, 'Asado');
      expect(grupos.first.saldo, 3000);
    },
  );

  test(
    'Una base creada por una version anterior recibe las tablas nuevas',
    () async {
      // Se recrea una base tal como la dejaba la version anterior de la app:
      // SOLO la tabla gastos (sin ingresos, metas, grupos ni servicios).
      final String ruta = '$_dirTest/finanzapp_77.db';
      final Database vieja = await databaseFactory.openDatabase(ruta);
      await vieja.execute('CREATE TABLE gastos ('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'concepto TEXT, monto REAL, categoria TEXT, '
          'expiration TEXT, fqYear INTEGER, fqHalfYear INTEGER, '
          'fqMonth INTEGER);');
      await vieja.execute(
        "INSERT INTO gastos (concepto, monto) VALUES ('Viejo', 100);",
      );
      await vieja.close();

      // Al abrir esa misma base con la app actual, las tablas nuevas tienen
      // que existir (antes solo se creaban al crear el archivo, y una cuenta
      // existente ya tiene su archivo).
      await DbHelper().setCurrentUser(77);

      final List<Gasto> gastos = await GastoRepository().getGastos();
      expect(gastos, hasLength(1), reason: 'Se perdieron los gastos viejos');
      expect(gastos.first.concepto, 'Viejo');

      // Las tablas nuevas responden sin lanzar "no such table".
      expect(await IngresoRepository().getIngresos(), isEmpty);
      expect(await MetaAhorroRepository().getMetas(), isEmpty);
      expect(await GrupoRepository().getGrupos(), isEmpty);
      expect(await ServicioHogarRepository().getServicios(), isEmpty);

      // Ademas se puede escribir en ellas.
      await IngresoRepository()
          .addIngreso(Ingreso('Sueldo', 1000, '2026-11-01'));
      expect(await IngresoRepository().getIngresos(), hasLength(1));

      // Y la base de usuarios global sigue intacta.
      final List<Usuario> usuarios = await UsuarioRepository().getUsuarios();
      expect(usuarios, isNotEmpty);
    },
  );
}
