# Changelog

Registro de los cambios funcionales de FinanzApp y de los errores que
aparecieron durante su desarrollo, con su causa y cómo se resolvieron.

Estado al cierre de este registro: `flutter analyze` sin issues y
**36 tests en verde** (`flutter test`).

---

## [Diseño de inicio] — 2026-11-05

### Introducción (primera vez que se abre la app)

- Pantalla nueva `lib/ui/onboarding_screen.dart` con **3 diapositivas**:
  bienvenida, "Todo conectado a tu saldo" y "Grupos y metas". Cada una tiene
  una ilustración hecha con íconos sobre un degradado azul.
- Botones **Omitir**, **Siguiente** y **Comenzar**, con indicadores de página.
- Se muestra **solo la primera vez**: el marcador se guarda en
  `finanzapp_introduccion.txt` (`DbHelper.introduccionVista` /
  `marcarIntroduccionVista`), igual que la sesión.
- Si hay sesión guardada, la app entra directo y no muestra la introducción.

### Login y registro

- Encabezado compartido con degradado azul (`CabeceraAuth`) y tarjeta blanca
  para los campos (`lib/ui/auth_widgets.dart`).
- Íconos en los campos y botón para **mostrar u ocultar la contraseña**.
- Textos con tildes: "Iniciar sesión", "Contraseña", "Ingresá",
  "Credenciales inválidas".
- La lógica no cambió: mismos validadores, mismo orden de campos y mismos
  botones.

### Cabecera y barra inferior

- Cabecera: título "FinanzApp" con el mes, campana con punto rojo cuando
  hay alertas, y **avatar con la inicial** de la cuenta activa (abre el perfil).
- "Crear cuenta" e "Iniciar sesión" salieron del header y pasaron al
  **perfil**, en la sección "Cuentas".
- Barra inferior con `BottomAppBar` y el botón **"+" centrado**. Quedan
  **4 accesos** (Inicio, Mes, Grupo, Ahorro), 2 a cada lado.
- **Hogar salió de la barra**: ahora es un botón **"Hogar"** en Inicio, en la
  misma fila que "Agregar ingreso". Abre la pantalla de servicios como
  pantalla propia y, al volver, recarga Inicio y la cabecera.

### Pantallas angostas

- Las filas que antes tenían ancho fijo ahora se adaptan (`Expanded`,
  `Flexible`, `FittedBox`, texto con `maxLines`/`ellipsis`) en Inicio, Mes,
  Ahorro, Hogar y la barra inferior.
- Test nuevo `test/pantalla_chica_test.dart`: recorre las secciones con un
  celular de 320×568 y falla si aparece un desborde.

### Tests

- 36 tests en verde. Nuevos: `introduccion_test.dart` (la introducción se
  muestra una sola vez) y `pantalla_chica_test.dart`.
- Los tests que abren la app marcan la introducción como vista.
- Los pasos que usaban los íconos del header ahora abren "Mi perfil" primero.

---

## Errores encontrados en este bloque

| Error | Causa | Solución |
|---|---|---|
| Tests de "Notificaciones" no encontraban la campana | Se cambió el ícono a `notifications_none_rounded` y los tests buscan `notifications_none` | Se volvió al ícono original |
| Inicio no mostraba "Aun no hay gastos registrados." | `BottomAppBar` de Material 3 mide **80 px** por defecto; la barra anterior medía 56 px, así que el contenido quedaba debajo del borde visible | Altura fijada en 60 px |
| Test de perfil no encontraba el avatar | Se tocaba el emoji 😊, que ya no existe (el avatar muestra la inicial) | Los tests usan `find.byTooltip('Mi perfil')` |
| El "+" se montaba sobre "Hogar" | Los 5 accesos eran columnas iguales con el hueco al centro; 2 a la izquierda y 3 a la derecha corrían el hueco | Dos mitades iguales y hueco central de 80 px |
| Desborde "RenderFlex overflowed" al achicar la ventana | Las etiquetas de la barra se partían en dos líneas y la columna superaba la altura | Etiquetas con `maxLines: 1` |
| Botón "Hogar" fuera de la vista en Inicio | Al agregar el botón, la lista de Inicio creció y el texto de gastos quedó debajo | Botón en la misma fila que "Agregar ingreso" |
| Test de Metas fallaba al tocar "Ahorro" | Un cierre de la pantalla de Hogar quedó al inicio del test de Metas (no al final del de servicios) | Se movió al final del test que corresponde |
| Test de pantalla chica: `Scaffold.geometryOf()` | Toque sobre un `BottomAppBar` con muesca antes de que la pantalla se pintara | Frames extra antes de tocar la barra |
| Desbordes en Inicio, Mes, Ahorro y Hogar | Filas con ancho fijo: título + botón, indicadores de 3 columnas, nombre del mes | Widgets que se adaptan al ancho (ver "Pantallas angostas") |
| Test de pantalla chica: "Hogar" no encontrado | Inicio es una lista perezosa: el botón queda fuera del área construida | `scrollUntilVisible` antes de tocar |

**Observación sobre los tests:** `flutter test` mide el texto con una fuente de
prueba más ancha que Roboto, así que el test de pantalla chica es más estricto
que un celular real. No se cargó una fuente del sistema para no depender de
la máquina.

---

## [Sin versión] — Rama `v2-arquitectura`

### Seguridad

- Contraseñas hasheadas con **SHA-256 + sal derivada del email**
  (`lib/data/contrasena.dart`); nunca se guardan en texto plano.
- **Sesión persistente** en `finanzapp_sesion.txt`: la app recuerda al
  usuario entre ejecuciones y ofrece cierre de sesión desde el perfil.
- Validaciones de registro y edición de perfil (email único, campos
  obligatorios, confirmación de contraseña).

### Notificaciones

- Utilidad `lib/util/notificaciones.dart`: genera avisos de **servicios
  del hogar pendientes/vencidos** y de **metas de ahorro** próximas a su
  fecha objetivo.
- Pantalla de notificaciones conectada a esa utilidad (no es mock).

### Todo conectado al saldo del inicio

- **Tarjeta "Saldo total"** en Inicio (`saldoTotal` en
  `lib/util/utils.dart`): ingresos − gastos − plata depositada en ahorros.
- **Gastos sin vencimiento**: campo "Fecha" único; los campos de
  vencimiento quedaron opcionales.
- **Servicios del hogar**: marcar como pagado crea un gasto asociado
  (`ServicioHogar.gastoId`); desmarcarlo lo elimina; editar un servicio
  pagado actualiza el gasto.
- **Ahorros**: depositar baja el saldo disponible y retirarlo lo sube.
- **Grupos**: los pagos y cobros quedan registrados como gastos.

### Deudas individuales por grupo

- Nueva entidad `MiembroGrupo` (grupoId, nombre, deuda con signo) y
  tabla `grupo_miembros`; `DbHelper.listar` ahora acepta filtro
  `where`/`args`.
- Repositorio `lib/data/miembro_grupo_repository.dart` (mock + SQLite).
  `GrupoRepository.addGrupo` ahora devuelve el id.
- **Alta de grupo**: se cargan los nombres de los integrantes
  (separados por coma) en vez de un número; el grupo arranca sin deudas.
- **Pantalla nueva `lib/ui/grupo_detalle_screen.dart`** (ficha del grupo):
  - resumen total del grupo (`totalDeudasGrupo` en `lib/util/utils.dart`);
  - cada integrante con su deuda individual: *Me debe* / *Le debés* /
    *Al día*;
  - menú por integrante: **Editar deuda** (dirección *Me debe* / *Le
    debés* + monto), **Pagar**, **Me pagan**, **Eliminar**;
  - **Pagar** crea un gasto positivo (resta plata) y **Me pagan** un
    gasto negativo (suma plata), sin poder superar el monto adeudado;
  - el saldo total del grupo se recalcula y persiste en cada cambio y se
    refleja en la tarjeta del grupo.
- En `groups_screen.dart` el menú de la tarjeta pasó a *Ver deudas* /
  *Eliminar* (las acciones de pago a nivel grupo se movieron a la ficha);
  tocar la tarjeta también abre la ficha.

### Tests

- 34 tests en verde. Nuevos: seguridad (`seguridad_test.dart`),
  notificaciones (`notificaciones_test.dart`), deudas individuales de
  grupos, alta de grupo con integrantes, integración con el saldo del
  inicio y regresión del bug de solo lectura (`migracion_test.dart`).

---

## Errores encontrados y resueltos

### 1. `Database readonly` al crear un grupo (crítico)

**Síntoma:** `SqfliteFfiException ... Database readonly` en
`INSERT INTO grupos ...` con `readOnly: true, singleInstance: true` al
crear un grupo (aunque la app parecía funcionar normal).

**Causa raíz:** `DbHelper._migrarCuentasExistentes` abría todas las
bases de cuentas con `readOnly: true` para leer una tabla vieja
`usuarios`. Las bases creadas por la versión actual **no tienen** esa
tabla, la lectura fallaba y el `close()` (que estaba después de la
lectura, no en un `finally`) quedaba saltado. sqflite cachea conexiones
por ruta (`singleInstance`), así que al entrar a la cuenta,
`openDatabase` devolvía **esa misma conexión en solo lectura**: los
SELECT funcionaban y el primer INSERT reventaba.

**Fix:** en `lib/data/dbhelper.dart`, la apertura de migración ahora se
hace con `singleInstance: false` (nunca se cachea la conexión de
solo lectura) y el `close()` va en un `finally` (se libera aunque la
lectura falle). Los datos no se dañaron: `readOnly` es una marca de la
conexión, no del archivo.

**Test de regresión:** `test/migracion_test.dart` — "La migracion de
cuentas no deja la base del usuario en solo lectura" (fallaba con el
mismo error antes del fix).

### 2. Errores de tests durante el desarrollo

| Error | Causa | Solución |
|---|---|---|
| `Found 0 widgets with text "Inicio"` | La ficha del grupo cubría la barra de navegación | `pop()` de la ficha antes de cambiar de pantalla |
| Menús de grupos no encontrados | `find.ancestor` no matcheaba el `PopupMenuButton` | Buscar por `find.byTooltip(...)` |
| Widgets "fuera del viewport" (800x600) | Menús y botones bajo el pliegue | `ensureVisible` / `scrollUntilVisible` antes del tap |
| Mensaje de validación vacío | Texto largo fuera de pantalla | `find.textContaining` + diálogos con `SingleChildScrollView` |
| `mock_test` con asserts en rojo | Los asserts quedaron desactualizados al cambiar los repositorios | Asserts actualizados al nuevo comportamiento |

---

## Commits previos (contexto)

- `4dc5658` feat: arquitectura por capas, SQLite multiusuario y perfil
- `9c80c59` feat: repositorios con fuente de datos conmutable (mock <-> SQLite)
- `ca6a1df` Quitar version web, README actualizado y tests portables
