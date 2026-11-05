// Tests de las notificaciones REALES de FinanzApp.
//
// Cubren dos cosas:
//   1. La logica pura que convierte los datos de la cuenta en notificaciones
//      (servicios pendientes y metas; los gastos no vencen y no avisan).
//   2. La pantalla: muestra las alertas calculadas y el estado vacio.
//
// Se usa SQLite real (FFI, en el mismo proceso) sobre un directorio PROPIO:
// flutter test ejecuta los archivos de test en paralelo.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/data/dbhelper.dart';
import 'package:flutter_application_1/data/fuente_datos.dart';
import 'package:flutter_application_1/data/gasto_repository.dart';
import 'package:flutter_application_1/data/servicio_hogar_repository.dart';
import 'package:flutter_application_1/data/usuario_repository.dart';
import 'package:flutter_application_1/model/model.dart';
import 'package:flutter_application_1/util/notificaciones.dart';

// Ruta aislada para las bases de datos de estos tests.
final String _dirTest =
    '${Directory.systemTemp.path}${Platform.pathSeparator}finanzapp_test_dbs_notif';

Future<void> esperarBD(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

// Abre la bienvenida y crea una cuenta nueva, quedando en el Inicio.
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

  // Fecha fija para que los casos sean deterministas.
  final DateTime hoy = DateTime(2026, 11, 4);

  group('Logica pura de notificaciones', () {
    test('Los gastos no generan alertas: un gasto no vence', () {
      final List<Notificacion> lista = generarNotificaciones(
        servicios: <ServicioHogar>[],
        metas: <MetaAhorro>[],
        hoy: hoy,
      );

      // Ni los gastos viejos ni los que "vencen hoy" producen avisos.
      expect(lista, isEmpty);
    });

    test('Solo los servicios pendientes generan alerta', () {
      final List<Notificacion> lista = generarNotificaciones(
        servicios: <ServicioHogar>[
          ServicioHogar('Luz', '', 9000, 0),
          ServicioHogar('Agua', '', 3000, 1),
        ],
        metas: <MetaAhorro>[],
        hoy: hoy,
      );

      expect(lista, hasLength(1));
      expect(lista.first.titulo, 'Servicio pendiente');
      expect(lista.first.tipo, TipoNotificacion.pendiente);
      expect(lista.first.detalle, contains('Luz'));
    });

    test('Las metas generan alerta al completarse, vencer o estar cerca', () {
      final List<Notificacion> lista = generarNotificaciones(
        servicios: <ServicioHogar>[],
        metas: <MetaAhorro>[
          MetaAhorro('Completa', 'Viajes', 100, 150, '2026-12-01'),
          MetaAhorro('Vencida', 'Hogar', 100, 50, '2026-10-01'),
          MetaAhorro('Proxima', 'Auto', 100, 50, '2026-11-10'),
          MetaAhorro('Lejana', 'Auto', 100, 50, '2027-06-01'),
        ],
        hoy: hoy,
      );

      // "Lejana" esta lejos y no esta completa: no avisa.
      expect(lista, hasLength(3));
      expect(
        lista.map((Notificacion n) => n.titulo).toList(),
        <String>['Meta vencida', 'Fecha objetivo próxima', 'Meta alcanzada'],
        reason: 'El orden tiene que ser por prioridad',
      );
    });

    test('Sin datos no hay notificaciones', () {
      expect(
        generarNotificaciones(
          servicios: <ServicioHogar>[],
          metas: <MetaAhorro>[],
          hoy: hoy,
        ),
        isEmpty,
      );
    });
  });

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

  // La sesion guardada hace que la app arranque directo en el inicio.
  setUp(() async {
    await DbHelper().cerrarSesion();
  });

  testWidgets(
    'La pantalla muestra las alertas reales de la cuenta',
    timeout: const Timeout(Duration(seconds: 60)),
    (WidgetTester tester) async {
      // La cuenta y sus datos se crean ANTES de arrancar la app y dentro de
      // un solo runAsync (zona real). Si la E/S de SQLite se mezcla con la
      // zona de tiempo falsa de los widgets, una operacion queda a medias y
      // la siguiente se bloquea esperandola para siempre (deadlock: runAsync
      // no puede hacer pump para desatascarla).
      final DateTime hoy = DateTime.now();
      String fecha(int dias) =>
          hoy.add(Duration(days: dias)).toIso8601String().substring(0, 10);

      await tester.runAsync<void>(() async {
        final int userId = await UsuarioRepository().crearUsuario(
          nombre: 'Nora Gil',
          email: 'nora@test.com',
          password: '123456',
        );
        await UsuarioRepository().guardarSesion(userId);
        await GastoRepository().addGasto(
          Gasto('Alquiler', 1500, 'Servicios', fecha(-10), 1, 1, 1),
        );
        await GastoRepository().addGasto(
          Gasto('Internet', 800, 'Servicios', fecha(10), 1, 1, 1),
        );
        await ServicioHogarRepository().addServicio(
          ServicioHogar('Luz', '', 9000, 0),
        );
      });

      // Con la sesion guardada, la app entra directo al inicio con los datos.
      await tester.pumpWidget(const FinanzApp());
      await tester.pumpAndSettle();
      await esperarBD(tester);

      await tester.tap(find.byIcon(Icons.notifications_none));
      // E/S real primero (esperarBD), animacion despues (pumpAndSettle):
      // el spinner del FutureBuilder no deja terminar a pumpAndSettle si la
      // carga todavia no se resolvio.
      await tester.pump();
      await esperarBD(tester);
      await tester.pumpAndSettle();

      expect(find.text('Servicio pendiente'), findsOneWidget);
      // Los gastos (por viejos o por "por vencer") ya no generan alertas.
      expect(find.text('Gasto vencido'), findsNothing);
      expect(find.text('Gasto por vencer'), findsNothing);
      // No hay mensajes fijos de la version anterior.
      expect(find.text('Pago confirmado'), findsNothing);
      expect(find.text('Nuevo integrante'), findsNothing);
    },
  );

  testWidgets(
    'Una cuenta sin movimientos muestra el estado vacio',
    (WidgetTester tester) async {
      await crearCuenta(tester, nombre: 'Omar Ruiz', email: 'omar@test.com');

      await tester.tap(find.byIcon(Icons.notifications_none));
      // Mismo orden que en el test anterior: E/S real primero, animacion
      // despues (ver comentario ahi).
      await tester.pump();
      await esperarBD(tester);
      await tester.pumpAndSettle();

      expect(find.text('No hay notificaciones por ahora.'), findsOneWidget);
      expect(find.text('Gasto vencido'), findsNothing);
    },
  );
}
