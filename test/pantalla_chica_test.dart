// Test de pantallas angostas: recorre las secciones con el tamaño de un
// celular chico (320x568). Cualquier desborde de diseno (RenderFlex
// overflowed, etc.) hace fallar el test.
//
// Usa un directorio PROPIO porque flutter test ejecuta los archivos en
// paralelo y comparten la carpeta de bases de datos.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_application_1/data/dbhelper.dart';
import 'package:flutter_application_1/data/fuente_datos.dart';
import 'package:flutter_application_1/main.dart';

final String _dirTest =
    '${Directory.systemTemp.path}${Platform.pathSeparator}finanzapp_test_dbs_pantalla_chica';

Future<void> esperarBD(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump();
}

// Espera (en tiempo real) a que aparezca un widget: el arranque abre y
// migra la base, y puede tardar mas que una espera fija.
Future<void> esperarHasta(WidgetTester tester, Finder buscado) async {
  for (int i = 0; i < 50 && buscado.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
  }
}

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
    await DbHelper().marcarIntroduccionVista();
  });

  setUp(() async {
    await DbHelper().cerrarSesion();
  });

  testWidgets('Las secciones principales no desbordan en una pantalla chica', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FinanzApp());
    await tester.pumpAndSettle();
    await esperarHasta(tester, find.widgetWithText(OutlinedButton, 'Crear cuenta'));

    // Se crea una cuenta para llegar a las pantallas principales.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    await esperarBD(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'Chica Prueba');
    await tester.enterText(find.byType(TextFormField).at(1), 'chica@test.com');
    await tester.enterText(find.byType(TextFormField).at(2), '123456');
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    await esperarHasta(tester, find.text('Inicio'));
    await tester.pumpAndSettle();
    await esperarBD(tester);

    // Recorrido por la barra inferior y por Hogar (desde Inicio).
    for (final String seccion in <String>['Mes', 'Grupo', 'Ahorro', 'Inicio']) {
      await tester.tap(find.text(seccion));
      await tester.pumpAndSettle();
      await esperarBD(tester);
    }

    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    await esperarBD(tester);
    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Hogar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Hogar'));
    await tester.pumpAndSettle();
    await esperarBD(tester);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    // Perfil desde el avatar.
    await tester.tap(find.byTooltip('Mi perfil'));
    await tester.pumpAndSettle();
    await esperarBD(tester);
    expect(find.text('Mi Perfil'), findsOneWidget);
  });
}
