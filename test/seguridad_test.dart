// Tests de seguridad de las cuentas de FinanzApp:
//   1. El registro no permite correos repetidos (ni por mayusculas).
//   2. La contrasena se guarda hasheada (SHA-256) y nunca en texto plano.
//   3. Una cuenta vieja con contrasena en claro entra al login y al hacerlo
//      queda migrada a hash.
//   4. La sesion se recuerda al "reiniciar" la app y se borra al cerrarla.
//   5. El perfil no permite tomar un correo que ya usa otra cuenta.
//
// Se usa SQLite real (FFI, en el mismo proceso) sobre un directorio PROPIO:
// flutter test ejecuta los archivos de test en paralelo, asi que no se puede
// compartir la carpeta con el resto de los tests.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/data/contrasena.dart';
import 'package:flutter_application_1/data/dbhelper.dart';
import 'package:flutter_application_1/data/fuente_datos.dart';
import 'package:flutter_application_1/data/usuario_repository.dart';
import 'package:flutter_application_1/model/model.dart';

// Ruta aislada para las bases de datos de estos tests.
final String _dirTest =
    '${Directory.systemTemp.path}${Platform.pathSeparator}finanzapp_test_dbs_seguridad';

// Da vueltas al event loop real del sistema (SQLite hace E/S) y redibuja.
Future<void> esperarBD(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

// Deja pasar el tiempo del snackbar para que no tape los elementos siguientes.
Future<void> esperarSnackbar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

// Abre la bienvenida y crea una cuenta nueva, quedando en el Inicio.
Future<void> crearCuenta(
  WidgetTester tester, {
  required String nombre,
  required String email,
  String password = '123456',
}) async {
  await tester.pumpWidget(const FinanzApp());
  await tester.pumpAndSettle();
  await esperarBD(tester);

  await tester.tap(find.widgetWithText(OutlinedButton, 'Crear cuenta'));
  await tester.pumpAndSettle();
  await esperarBD(tester);

  await tester.enterText(find.byType(TextFormField).at(0), nombre);
  await tester.enterText(find.byType(TextFormField).at(1), email);
  await tester.enterText(find.byType(TextFormField).at(2), password);

  await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
  await tester.pumpAndSettle();
  await esperarBD(tester);
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

  // La sesion guardada hace que la app arranque directo en el inicio:
  // cada test tiene que partir de la pantalla de bienvenida.
  setUp(() async {
    await DbHelper().cerrarSesion();
  });

  testWidgets(
    'El registro no permite correos repetidos',
    (WidgetTester tester) async {
      await crearCuenta(
        tester,
        nombre: 'Ana Torres',
        email: 'repetida@test.com',
      );

      // ---------------------------------------------------------------
      // 1. ALTA DE UNA SEGUNDA CUENTA CON EL MISMO CORREO
      // ---------------------------------------------------------------
      await tester.tap(find.byIcon(Icons.person_add_outlined));
      await tester.pumpAndSettle();
      await esperarBD(tester);
      expect(find.text('Nueva cuenta'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Otra Persona');
      await tester.enterText(
          find.byType(TextFormField).at(1), 'repetida@test.com');
      await tester.enterText(find.byType(TextFormField).at(2), '123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      expect(find.text('Ya existe una cuenta con ese correo'), findsOneWidget);
      expect(find.text('Nueva cuenta'), findsOneWidget,
          reason: 'Tenia que seguir en el formulario de alta');
      await esperarSnackbar(tester);

      // ---------------------------------------------------------------
      // 2. TAMPOCO PASA CAMBIANDO SOLO LAS MAYUSCULAS
      // ---------------------------------------------------------------
      await tester.enterText(
          find.byType(TextFormField).at(1), 'REPETIDA@test.com');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      expect(find.text('Ya existe una cuenta con ese correo'), findsOneWidget);
      await esperarSnackbar(tester);

      // ---------------------------------------------------------------
      // 3. EN LA BASE SOLO QUEDO UNA CUENTA CON ESE CORREO
      // ---------------------------------------------------------------
      final List<Usuario>? usuarios =
          await tester.runAsync<List<Usuario>>(
              () => UsuarioRepository().getUsuarios());
      expect(usuarios, hasLength(1),
          reason: 'El registro duplicado no debio guardarse');
    },
  );

  test(
    'La contraseña se guarda hasheada y nunca en texto plano',
    () async {
      final int id = await UsuarioRepository().crearUsuario(
        nombre: 'Carla Sosa',
        email: 'carla@test.com',
        password: 'secreta123',
      );

      final Usuario? usuario = await UsuarioRepository().getUsuario(id);
      expect(usuario, isNotNull);

      // En la base NO queda la contrasena original.
      expect(usuario!.password, isNot('secreta123'));
      expect(esHashContrasena(usuario.password), isTrue,
          reason: 'Se esperaba un hash SHA-256 de 64 caracteres');
      expect(usuario.password, hashContrasena('carla@test.com', 'secreta123'));

      // El login se resuelve contra el hash.
      expect(contrasenaCorrecta(usuario, 'secreta123'), isTrue);
      expect(contrasenaCorrecta(usuario, 'clave-mala'), isFalse);

      // Dos cuentas con la misma contrasena tienen hashes distintos (sal).
      final int otroId = await UsuarioRepository().crearUsuario(
        nombre: 'Diego Sosa',
        email: 'diego@test.com',
        password: 'secreta123',
      );
      final Usuario? otro = await UsuarioRepository().getUsuario(otroId);
      expect(otro!.password, isNot(usuario.password));
    },
  );

  testWidgets(
    'Una cuenta con contraseña en claro entra al login y queda migrada',
    (WidgetTester tester) async {
      // Se recrea una cuenta tal como la dejaba la version anterior:
      // la contrasena guardada directamente en texto plano.
      // Los accesos a SQLite se hacen con runAsync porque son E/S real y
      // dentro de la zona de tiempo del test no se resuelven solos.
      int? idCuenta;
      await tester.runAsync<void>(() async {
        final int id = await DbHelper().siguienteIdUsuario();
        await DbHelper().insertUser(
          Usuario('Cuenta Vieja', 'vieja@test.com', 'claveVieja', id),
        );
        await DbHelper().setCurrentUser(id);
        idCuenta = id;
      });

      await tester.pumpWidget(const FinanzApp());
      await tester.pumpAndSettle();
      await esperarBD(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'vieja@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'claveVieja');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      // La cuenta vieja sigue pudiendo entrar.
      expect(find.text('Gastos del mes'), findsWidgets);
      expect(find.text('Iniciar sesión'), findsNothing);

      // Y tras el login la contrasena quedo guardada como hash.
      final Usuario? migrada =
          await tester.runAsync<Usuario?>(
              () => UsuarioRepository().getUsuario(idCuenta!));
      expect(migrada, isNotNull);
      expect(esHashContrasena(migrada!.password), isTrue,
          reason: 'El login debio migrar la contrasena a hash');
      expect(contrasenaCorrecta(migrada, 'claveVieja'), isTrue);
    },
  );

  testWidgets(
    'La sesión se recuerda al reiniciar y se borra al cerrarla',
    (WidgetTester tester) async {
      await crearCuenta(tester, nombre: 'Paula Lima', email: 'paula@test.com');

      // ---------------------------------------------------------------
      // 1. "REINICIO" CON SESION GUARDADA -> ENTRA DIRECTO AL INICIO
      // ---------------------------------------------------------------
      // Una key distinta fuerza un estado nuevo (como un arranque real).
      await tester.pumpWidget(const FinanzApp(key: ValueKey('arranque-2')));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      expect(find.text('Iniciar sesión'), findsNothing);
      expect(find.text('Gastos del mes'), findsWidgets);

      // ---------------------------------------------------------------
      // 2. CERRAR SESION -> VUELVE A LA BIENENDIDA Y BORRA LA SESION
      // ---------------------------------------------------------------
      await tester.tap(find.text('😊'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Gastos del mes'), findsNothing);

      // ---------------------------------------------------------------
      // 3. OTRO "REINICIO" SIN SESION -> PIDE INICIAR SESION OTRA VEZ
      // ---------------------------------------------------------------
      await tester.pumpWidget(const FinanzApp(key: ValueKey('arranque-3')));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Gastos del mes'), findsNothing);
    },
  );

  testWidgets(
    'El perfil no permite usar un correo ya registrado',
    (WidgetTester tester) async {
      await crearCuenta(tester, nombre: 'Ana Torres', email: 'ana@test.com');

      // Se crea una segunda cuenta desde la barra superior.
      await tester.tap(find.byIcon(Icons.person_add_outlined));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Bruno Diaz');
      await tester.enterText(
          find.byType(TextFormField).at(1), 'bruno@test.com');
      await tester.enterText(find.byType(TextFormField).at(2), '123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear cuenta'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      // Bruno edita su perfil y pone el correo de Ana.
      await tester.tap(find.text('😊'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Editar datos'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextFormField).at(1), 'ana@test.com');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar cambios'));
      await tester.pumpAndSettle();
      await esperarBD(tester);

      expect(find.text('Ese correo ya está en uso'), findsOneWidget);
      // Se sigue en modo edicion: el cambio no se aplico.
      expect(find.widgetWithText(ElevatedButton, 'Guardar cambios'),
          findsOneWidget);
      await esperarSnackbar(tester);

      // La cuenta de Bruno conserva su correo original.
      final Usuario? bruno = await tester.runAsync<Usuario?>(
          () => UsuarioRepository().getUsuarioPorEmail('bruno@test.com'));
      expect(bruno, isNotNull);
      expect(bruno!.email, 'bruno@test.com');
    },
  );
}
