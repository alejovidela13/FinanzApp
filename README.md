# FinanzApp

Aplicación de finanzas personales hecha con Flutter. Permite registrar cuentas,
gastos, ingresos, metas de ahorro, servicios del hogar y grupos de gastos.

## Requisitos

- **Flutter SDK 3.x** con Dart **3.13.2 o superior** (instalación oficial:
  https://docs.flutter.dev/get-started/install). Verificá con `flutter --version`.
- **Git** (para clonar el repositorio).
- Para correr en **Windows**: Visual Studio 2022 (o Build Tools) con la carga de
  trabajo **"Desarrollo de escritorio con C++"**.
- Para correr en **Linux**: paquetes de GTK y CMake (`sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev`).
- Para correr en **Android**: Android Studio con el SDK de Android.

No hace falta instalar extensiones: alcanza con el SDK de Flutter. Un editor
(VS Code o Android Studio) es opcional.

## Cómo ejecutarla

```bash
git clone <url-del-repositorio>
cd FinanzApp-2-arquitectura
flutter pub get
flutter run -d windows   # o -d linux / -d <id-de-tu-emulador-android>
```

La primera compilación puede tardar varios minutos. Durante el build se descarga
automáticamente `sqlite3.dll` (Windows), por lo que necesita conexión a internet.

Para ver los dispositivos disponibles: `flutter devices`.

## Cuenta de prueba

Al iniciar, la app crea la cuenta:

- Email: `test@finanzapp.com`
- Contraseña: `123456`

## Modo demo

En `lib/data/fuente_datos.dart`, la variable `FuenteDatos.usarMock` controla
de dónde salen los datos:

- `true` (valor actual): modo demo, los datos son de ejemplo y se guardan solo en memoria.
- `false`: los datos se guardan en SQLite.

Las cuentas de usuario siempre se guardan en SQLite, aunque esté activo el modo demo.

## Tests

```bash
flutter test
```

## Plataformas

- **Windows**: probada (análisis y tests pasan).
- **Linux y Android**: no probadas todavía.
- **Web**: no es compatible. El código usa `dart:io`, que no existe en el navegador.
