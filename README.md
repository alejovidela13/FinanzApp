# FinanzApp

Aplicación de finanzas personales hecha con Flutter. Permite registrar cuentas,
gastos, ingresos, metas de ahorro, servicios del hogar y grupos de gastos,
y editarlos o eliminarlos cuando se necesite.

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

- `false` (valor actual): los datos se guardan en SQLite.
- `true`: modo demo, los datos son de ejemplo y se guardan solo en memoria.

Las cuentas de usuario siempre se guardan en SQLite, aunque esté activo el modo demo.

## Seguridad de las cuentas

- **Contraseñas hasheadas**: nunca se guardan en texto plano. Se almacena el
  hash SHA-256 de `email|contraseña` (`lib/data/contrasena.dart`), de modo que
  cada cuenta tiene su propio hash aunque use la misma contraseña.
- **Cuentas viejas**: si una contraseña estaba en claro, se acepta en el login
  y queda migrada a hash automáticamente.
- **Correo único**: no se pueden crear dos cuentas con el mismo correo (tampoco
  cambiando mayúsculas/minúsculas), ni tomar un correo ya usado desde el perfil.
- **Sesión persistente**: la app recuerda al último usuario autenticado al
  reiniciar. Al cerrar sesión se borra ese registro y vuelve a pedir login.

## Notificaciones

La campana de la barra superior muestra un punto rojo cuando hay alertas
pendientes. Las notificaciones no son mensajes fijos: se calculan en el momento
a partir de los datos de la cuenta (`lib/util/notificaciones.dart`):

- **Servicios del hogar todavía sin pagar.**
- **Metas de ahorro**: alcanzadas, vencidas o con fecha objetivo próxima.

Se ordenan de más urgente a menos urgente. La pantalla de notificaciones se
actualiza cada vez que se abre. Los gastos no generan alertas: un gasto es
plata que ya salió, no algo que venza (la fecha del gasto sirve para
agruparlo por mes).

## Todo conectado al saldo del inicio

La tarjeta **Saldo total** del inicio muestra cuánta plata hay disponible:
`ingresos − gastos − plata depositada en ahorros + plata retirada`
(`saldoTotal` en `lib/util/utils.dart`). Todos los movimientos la modifican:

- **Servicios del hogar**: al marcar un servicio como pagado se registra
  automáticamente como gasto (categoría "Servicios", fecha de hoy), y al
  desmarcarlo ese gasto se elimina. Si se edita un servicio pagado, el gasto
  se actualiza junto con él.
- **Juntadas y Grupos**: cada grupo tiene sus integrantes con la deuda
  individual de cada uno ("me debe" / "le debo"). Registrar un pago o un
  cobro mueve esa deuda hacia cero y queda registrado como gasto: el pago
  resta plata y el cobro entra como gasto negativo (suma plata).
- **Ahorros**: depositar baja el saldo disponible y retirarlo lo sube (el
  dinero se mueve entre tu billetera y tus metas).

## Deudas individuales por grupo

Al crear un grupo se cargan los nombres de sus integrantes (todavía sin
deuda). Tocando la tarjeta del grupo —o la opción **Ver deudas** de su
menú— se abre la ficha con cada integrante:

- **Deuda individual**: cada integrante tiene su propia deuda con signo
  desde tu perspectiva: *Me debe $X* (verde), *Le debés $X* (rojo) o
  *Al día*. Se carga o corrige con **Editar deuda**, eligiendo la dirección
  (*Me debe* / *Le debés*) y el monto.
- **Pago y cobro**: las acciones **Pagar** (si le debés) y **Me pagan** (si
  te deben) mueven la deuda hacia cero y crean el gasto correspondiente —
  el pago resta plata del saldo del inicio y el cobro la suma — sin poder
  superar el monto adeudado.
- **Saldo total del grupo**: es la suma firmada de todas las deudas
  individuales (`totalDeudasGrupo` en `lib/util/utils.dart`); se
  recalcula y persiste en SQLite con cada cambio.

## Primera vez y navegación

- **Introducción**: al abrir la app por primera vez se muestran tres
  pantallas de bienvenida (se pueden omitir). No vuelven a aparecer.
- **Barra inferior**: Inicio, Mes, Grupo y Ahorro, con el botón **+** en el
  centro para cargar gastos.
- **Hogar** (servicios del hogar): se abre desde el botón "Hogar" de Inicio.
- **Perfil** (avatar de la cabecera): datos de la cuenta, crear otra cuenta,
  iniciar sesión con otra cuenta y cerrar sesión.

## Tests

```bash
flutter analyze
flutter test
```

Al cierre de este registro: `flutter analyze` sin issues y **36 tests en
verde**.

## Historial de cambios

Cada bloque funcional y los errores encontrados (con su causa y
solución) están registrados en [CHANGELOG.md](CHANGELOG.md).

## Plataformas

- **Linux**: probada (análisis y 36 tests pasan).
- **Windows**: sin probar en esta rama.
- **Android**: no probada todavía.
- **Web**: no es compatible. El código usa `dart:io`, que no existe en el navegador.
