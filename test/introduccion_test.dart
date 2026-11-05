// Test de la introduccion (pantallas de bienvenida): se muestra la primera
// vez que se abre la app y no vuelve a aparecer despues.
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
    '${Directory.systemTemp.path}${Platform.pathSeparator}finanzapp_test_dbs_introduccion';

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
  });

  setUp(() async {
    await DbHelper().cerrarSesion();
  });

  testWidgets('La introduccion se muestra una sola vez', (WidgetTester tester) async {
    // Primera apertura: sin marcador, se ven las pantallas de introduccion.
    await tester.pumpWidget(const FinanzApp());
    await tester.pumpAndSettle();
    await esperarHasta(tester, find.text('Bienvenido a FinanzApp'));

    expect(find.text('Bienvenido a FinanzApp'), findsOneWidget);
    expect(find.text('Omitir'), findsOneWidget);

    // Se recorren las tres diapositivas con "Siguiente".
    await tester.tap(find.widgetWithText(ElevatedButton, 'Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Todo conectado a tu saldo'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Grupos y metas'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Comenzar'));
    await tester.pumpAndSettle();
    await esperarHasta(tester, find.widgetWithText(OutlinedButton, 'Crear cuenta'));

    // Al terminar se llega a la bienvenida con los botones de acceso.
    expect(find.widgetWithText(OutlinedButton, 'Crear cuenta'), findsOneWidget);
    expect(await tester.runAsync(() => DbHelper().introduccionVista()), isTrue);

    // Segunda apertura: la introduccion ya no aparece.
    await tester.pumpWidget(const FinanzApp(key: ValueKey('segunda-apertura')));
    await tester.pumpAndSettle();
    await esperarHasta(tester, find.widgetWithText(OutlinedButton, 'Crear cuenta'));

    expect(find.text('Bienvenido a FinanzApp'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Crear cuenta'), findsOneWidget);
  });
}
