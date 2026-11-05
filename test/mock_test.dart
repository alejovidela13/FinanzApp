// Tests del MODO DEMO (mock).
//
// El interruptor FuenteDatos.usarMock = true hace que los repositorios
// devuelvan listas de prueba en memoria en lugar de leer SQLite.
// Estos tests comprueban:
//   * que el origen de datos simulado responda con sus datos de ejemplo,
//   * que el mock NO escriba en la base de datos,
//   * y que la interfaz se construya a partir de lo que devuelve el repositorio.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/data/dbhelper.dart';
import 'package:flutter_application_1/data/fuente_datos.dart';
import 'package:flutter_application_1/data/grupo_repository.dart';
import 'package:flutter_application_1/data/gasto_repository.dart';
import 'package:flutter_application_1/data/ingreso_repository.dart';
import 'package:flutter_application_1/data/meta_ahorro_repository.dart';
import 'package:flutter_application_1/data/servicio_hogar_repository.dart';
import 'package:flutter_application_1/model/model.dart';

// Ruta aislada para las bases de datos de estos tests.
final String _dirTest =
    '${Directory.systemTemp.path}${Platform.pathSeparator}finanzapp_test_dbs_mock';

Future<void> esperarBD(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // MODO DEMO activado: los repositorios trabajan sobre listas mock.
    FuenteDatos.usarMock = true;

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;

    final Directory dir = Directory(_dirTest);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    dir.createSync(recursive: true);
    await databaseFactory.setDatabasesPath(dir.path);
    await DbHelper().marcarIntroduccionVista();
  });

  // La sesion guardada en disco hace que la app arranque directo en el
  // inicio: cada test tiene que partir de la pantalla de bienvenida.
  setUp(() async {
    await DbHelper().cerrarSesion();
  });

  test(
    'Los repositorios responden con datos de prueba sin tocar SQLite',
    () async {
      // El interruptor esta en modo demo (es el valor con el que arranca la app).
      expect(FuenteDatos.usarMock, isTrue);

      // ---------------------------------------------------------------
      // 1. LOS REPOSITORIOS DEVUELVEN SUS DATOS DE EJEMPLO
      // ---------------------------------------------------------------
      final List<Gasto> gastos = await GastoRepository().getGastos();
      expect(gastos, hasLength(4));
      expect(gastos.first.concepto, 'Alquiler');

      expect(await IngresoRepository().getIngresos(), hasLength(2));
      expect(await MetaAhorroRepository().getMetas(), hasLength(3));
      expect(await GrupoRepository().getGrupos(), hasLength(4));
      expect(await ServicioHogarRepository().getServicios(), hasLength(4));

      // ---------------------------------------------------------------
      // 2. EL MOCK SIRVE PARA ESCRIBIR (alta y baja) PERO NO PERSISTE
      // ---------------------------------------------------------------
      await GastoRepository().addGasto(
        Gasto('Pago de prueba', 999, 'General', '2026-11-01', 1, 1, 1),
      );
      final List<Gasto> conAlta = await GastoRepository().getGastos();
      expect(conAlta, hasLength(5));

      // La base de datos NO se toco: sigue vacia.
      final List<Map<String, dynamic>> enSQLite =
          await DbHelper().listar('gastos');
      expect(enSQLite, isEmpty,
          reason: 'El mock no debe escribir en SQLite');

      // El alta le asigno un id unico dentro de la lista.
      expect(conAlta.last.id, 5);

      await GastoRepository().deleteGasto(5);
      expect(await GastoRepository().getGastos(), hasLength(4));

      // ---------------------------------------------------------------
      // 3. LA BAJA TAMBIEN VIVE SOLO EN LA LISTA
      // ---------------------------------------------------------------
      final List<MetaAhorro> metas = await MetaAhorroRepository().getMetas();
      await MetaAhorroRepository().deleteMeta(metas.first.id!);
      expect(await MetaAhorroRepository().getMetas(), hasLength(2));
      await MetaAhorroRepository().addMeta(metas.first);
      expect(await MetaAhorroRepository().getMetas(), hasLength(3));
    },
  );

  testWidgets(
    'La interfaz se construye a partir de los datos del repositorio (mock)',
    (WidgetTester tester) async {
      // ---------------------------------------------------------------
      // 1. SE CREA UNA CUENTA (el registro sigue siendo real, en SQLite)
      // ---------------------------------------------------------------
      await tester.pumpWidget(const FinanzApp());
      await tester.pumpAndSettle();
      await esperarBD(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Crear cuenta'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Demo User');
      await tester.enterText(find.byType(TextFormField).at(1), 'demo@test.com');
      await tester.enterText(find.byType(TextFormField).at(2), '123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      // ---------------------------------------------------------------
      // 2. EL INICIO MUESTRA LOS GASTOS DEL MOCK (no la base vacia)
      // ---------------------------------------------------------------
      expect(find.text('Aun no hay gastos registrados.'), findsNothing);

      // Saldo total del mock: ingresos 430000 - gastos 2870 - ahorros 520000.
      expect(find.text('-\$92870'), findsOneWidget);

      // Seccion de ingresos del mes: 350000 + 80000 (queda bajo el pliegue).
      await tester.scrollUntilVisible(
        find.text('Total \$430000 • 2 registro(s)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Total \$430000 • 2 registro(s)'), findsOneWidget);

      // Se baja hasta el ultimo gasto de ejemplo: los 4 tienen que estar.
      await tester.scrollUntilVisible(
        find.text('Entradas de cine'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Alquiler'), findsOneWidget);
      expect(find.text('Supermercado'), findsOneWidget);
      expect(find.text('Nafta'), findsOneWidget);
      expect(find.text('Entradas de cine'), findsOneWidget);

      // ---------------------------------------------------------------
      // 3. AHORRO TAMBIEN SE CONSTRUYE DESDE EL REPOSITORIO
      // ---------------------------------------------------------------
      await tester.tap(find.text('Ahorro'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      expect(find.text('Aún no tenés metas de ahorro. Creá una para empezar.'),
          findsNothing);
      expect(find.text('Vacaciones de verano'), findsOneWidget);
      // 175000 + 300000 + 45000 de las metas de ejemplo.
      expect(find.text('\$520000'), findsOneWidget);

      // ---------------------------------------------------------------
      // 4. MODO DEMO ACTIVO DURANTE TODA LA PRUEBA
      // ---------------------------------------------------------------
      expect(FuenteDatos.usarMock, isTrue);
    },
  );
}
