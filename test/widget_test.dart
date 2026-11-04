// Tests de la app FinanzApp.
//
// Cubren el flujo completo de principio a fin:
//   Bienvenida -> Registro -> Inicio -> Agregar gasto -> Cambiar de cuenta
//   -> Login con otra cuenta -> verificar que cada usuario ve SU base de datos.
//
// Se usa SQLite real (FFI, en el mismo proceso) sobre un directorio aislado,
// de modo que los tests nunca tocan las bases de datos de la aplicacion.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/data/dbhelper.dart';
import 'package:flutter_application_1/data/fuente_datos.dart';
import 'package:flutter_application_1/data/gasto_repository.dart';
import 'package:flutter_application_1/model/model.dart';
import 'package:flutter_application_1/data/usuario_repository.dart';

// Ruta aislada para las bases de datos de los tests.
final String _dirTest =
    '${Directory.systemTemp.path}${Platform.pathSeparator}finanzapp_test_dbs';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Estos tests verifican la PERSISTENCIA REAL: se desactiva el modo demo.
    FuenteDatos.usarMock = false;

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

  // La sesion guardada en disco hace que la app arranque directo en el
  // inicio: cada test tiene que partir de la pantalla de bienvenida.
  setUp(() async {
    await DbHelper().cerrarSesion();
  });

  testWidgets('FinanzApp muestra la pantalla de bienvenida', (WidgetTester tester) async {
    await tester.pumpWidget(const FinanzApp());
    await tester.pumpAndSettle();

    expect(find.text('FinanzApp'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });

  testWidgets(
    'Flujo completo: bienvenida -> registro -> gasto -> otra cuenta -> login',
    (WidgetTester tester) async {
      // ---------------------------------------------------------------
      // 1. LA APP ARRANCA EN LA PANTALLA DE BIENVENIDA
      // ---------------------------------------------------------------
      await tester.pumpWidget(const FinanzApp());
      await tester.pumpAndSettle();
      await esperarBD(tester);
      expect(find.text('Iniciar sesión'), findsOneWidget);

      // ---------------------------------------------------------------
      // 2. SE CREA LA CUENTA "ANA" -> ENTRA A LA PANTALLA DE INICIO
      // ---------------------------------------------------------------
      await tester.tap(find.widgetWithText(OutlinedButton, 'Crear cuenta'));
      await tester.pumpAndSettle();
      await esperarBD(tester);
      expect(find.text('Nueva cuenta'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Ana Perez');
      await tester.enterText(find.byType(TextFormField).at(1), 'ana@test.com');
      await tester.enterText(find.byType(TextFormField).at(2), '123456');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      // La cuenta nueva arranca con la base de datos vacia.
      expect(find.text('Aun no hay gastos registrados.'), findsOneWidget);

      // ---------------------------------------------------------------
      // 3. SE AGREGA UN GASTO Y APARECE EN EL INICIO
      // ---------------------------------------------------------------
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Alquiler');
      await tester.enterText(find.byType(TextFormField).at(1), '1500');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar gasto'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      // El resumen del mes siempre esta visible: confirma que el gasto se
      // guardo en SQLite y se reflejo en la interfaz.
      expect(find.text('\$1500'), findsWidgets);

      // El item del gasto queda por debajo de la tarjeta principal, asi que
      // hay que desplazar la lista para encontrarlo.
      await tester.scrollUntilVisible(
        find.text('Alquiler'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Alquiler'), findsOneWidget);
      // El item muestra la fecha en que se pago, sin textos de vencimiento.
      expect(find.text('Vence hoy'), findsNothing);
      expect(find.text('Vencido'), findsNothing);
      expect(find.textContaining('General •'), findsOneWidget);

      // ---------------------------------------------------------------
      // 4. SE CREA LA CUENTA "BRUNO" -> SU BASE ESTA VACIA (AISLAMIENTO)
      // ---------------------------------------------------------------
      await tester.tap(find.byIcon(Icons.person_add_outlined));
      await tester.pumpAndSettle();
      await esperarBD(tester);
      expect(find.text('Nueva cuenta'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Bruno Gomez');
      await tester.enterText(find.byType(TextFormField).at(1), 'bruno@test.com');
      await tester.enterText(find.byType(TextFormField).at(2), '654321');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      // Bruno NO ve el gasto de Ana: cada cuenta tiene su propia base.
      expect(find.text('Aun no hay gastos registrados.'), findsOneWidget);
      expect(find.text('Alquiler'), findsNothing);

      // ---------------------------------------------------------------
      // 5. LOGIN CON CREDENCIALES INVALIDAS -> MENSAJE DE ERROR
      // ---------------------------------------------------------------
      await tester.tap(find.byIcon(Icons.login_outlined));
      await tester.pumpAndSettle();
      await esperarBD(tester);
      expect(find.text('Iniciar sesion'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'ana@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'clave-mala');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      expect(find.text('Credenciales invalidas'), findsOneWidget);

      // ---------------------------------------------------------------
      // 6. LOGIN CORRECTO COMO ANA -> RECUPERA SUS GASTOS
      // ---------------------------------------------------------------
      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      // El login funciona desde cualquier sesion (registro global de cuentas)
      // y los gastos se leen desde la base propia de Ana.
      expect(find.text('Alquiler'), findsOneWidget);
      expect(find.text('Aun no hay gastos registrados.'), findsNothing);
    },
  );

  test(
    'Registrar cuentas tras reiniciar nunca falla con UNIQUE constraint',
    () async {
      // Reproduce el arranque de la aplicacion: sesion en el usuario 1 y
      // verificacion del usuario de prueba en el registro GLOBAL.
      await DbHelper().setCurrentUser(1);
      final Usuario? prueba =
          await DbHelper().getUsuarioPorEmail('test@finanzapp.com');
      if (prueba == null) {
        await UsuarioRepository().crearUsuario(
          nombre: 'Usuario Test',
          email: 'test@finanzapp.com',
          password: '123456',
        );
      }

      final Set<int> ids = <int>{};
      for (int i = 0; i < 3; i++) {
        // Cada vuelta simula un reinicio: la sesion vuelve al usuario 1 y,
        // aun asi, hay que poder crear una cuenta nueva sin chocar de id.
        await DbHelper().setCurrentUser(1);

        final int id = await UsuarioRepository().crearUsuario(
          nombre: 'Cuenta $i',
          email: 'cuenta$i@test.com',
          password: '1234',
        );

        expect(ids.contains(id), isFalse, reason: 'Se reutilizo el id $id');
        ids.add(id);

        // La cuenta nueva ademas arranca con la base de gastos vacia.
        final List<Gasto> gastos = await GastoRepository().getGastos();
        expect(gastos, isEmpty);
      }

      // Todas las cuentas quedan en el registro global y son recuperables.
      for (final int id in ids) {
        final Usuario? usuario = await UsuarioRepository().getUsuario(id);
        expect(usuario, isNotNull, reason: 'No se encontro la cuenta $id');
      }
    },
  );
}
