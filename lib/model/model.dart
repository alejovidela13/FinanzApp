// Entidades de datos de la aplicacion FinanzApp.
//
// Todas siguen el mismo patron:
//  * `id` nullable (todavia no persistido hasta que se guarda en SQLite)
//  * Constructor estandar `X(...)`    -> objetos nuevos creados en la UI
//  * Constructor nombrado `X.withId(...)` -> objetos recuperados de la base
//  * `toMap()`     -> Objeto Dart -> Map<String, dynamic> (fila de SQLite)
//  * `fromObject()` -> Map<String, dynamic> -> Objeto Dart tipado

/// Representacion logica de un gasto financiero.
class Gasto {
  int? id; // Identificador autoincremental de la DB (null antes de persistir)
  String concepto; // Concepto del gasto (ej. "Alquiler")
  double monto; // Monto del gasto
  String categoria; // Categoria del gasto (ej. "Servicios")
  String expiration; // Fecha de expiracion en formato String YYYY-MM-DD
  int fqYear; // Alerta: 1 si se notificara un ano antes, 0 si no
  int fqHalfYear; // Alerta: 1 si se notificaria seis meses antes, 0 si no
  int fqMonth; // Alerta: 1 si se notificaria un mes antes, 0 si no

  // Constructor estandar: para gastos nuevos creados en la interfaz visual.
  Gasto(this.concepto, this.monto, this.categoria, this.expiration, this.fqYear,
      this.fqHalfYear, this.fqMonth, [this.id]);

  // Constructor nombrado: para gastos recuperados desde la base de datos.
  Gasto.withId(this.id, this.concepto, this.monto, this.categoria,
      this.expiration, this.fqYear, this.fqHalfYear, this.fqMonth);

  // Serializacion: Objeto Dart -> Map<String, dynamic> (fila de SQLite)
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (id != null) {
      map['id'] = id;
    }
    map['concepto'] = concepto;
    map['monto'] = monto;
    map['categoria'] = categoria;
    map['expiration'] = expiration;
    map['fqYear'] = fqYear;
    map['fqHalfYear'] = fqHalfYear;
    map['fqMonth'] = fqMonth;
    return map;
  }

  // Deserializacion: Map<String, dynamic> (fila de SQLite) -> Objeto Dart tipado
  factory Gasto.fromObject(dynamic o) => Gasto.withId(
        o['id'],
        o['concepto'] ?? '',
        (o['monto'] as num?)?.toDouble() ?? 0.0,
        o['categoria'] ?? '',
        o['expiration'] ?? '',
        (o['fqYear'] as num?)?.toInt() ?? 0,
        (o['fqHalfYear'] as num?)?.toInt() ?? 0,
        (o['fqMonth'] as num?)?.toInt() ?? 0,
      );
}

/// Ingreso economico del usuario (sueldo, venta, freelance, etc.).
class Ingreso {
  int? id; // null hasta persistir
  String concepto; // Descripcion del ingreso (ej. "Sueldo")
  double monto; // Monto recibido
  String fecha; // Fecha en formato String YYYY-MM-DD

  // Constructor estandar: para ingresos nuevos creados en la interfaz visual.
  Ingreso(this.concepto, this.monto, this.fecha, [this.id]);

  // Constructor nombrado: para ingresos recuperados desde la base de datos.
  Ingreso.withId(this.id, this.concepto, this.monto, this.fecha);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (id != null) {
      map['id'] = id;
    }
    map['concepto'] = concepto;
    map['monto'] = monto;
    map['fecha'] = fecha;
    return map;
  }

  factory Ingreso.fromObject(dynamic o) => Ingreso.withId(
        o['id'],
        o['concepto'] ?? '',
        (o['monto'] as num?)?.toDouble() ?? 0.0,
        o['fecha'] ?? '',
      );
}

/// Meta de ahorro del usuario (ej. "Vacaciones de Verano").
class MetaAhorro {
  int? id; // null hasta persistir
  String titulo; // Nombre de la meta
  String categoria; // Categoria de la meta (ej. "Viajes")
  double montoObjetivo; // Monto que se quiere alcanzar
  double montoAhorrado; // Monto acumulado hasta ahora
  String fechaObjetivo; // Fecha limite en formato String YYYY-MM-DD

  // Constructor estandar: para metas nuevas creadas en la interfaz visual.
  MetaAhorro(this.titulo, this.categoria, this.montoObjetivo,
      this.montoAhorrado, this.fechaObjetivo, [this.id]);

  // Constructor nombrado: para metas recuperadas desde la base de datos.
  MetaAhorro.withId(this.id, this.titulo, this.categoria, this.montoObjetivo,
      this.montoAhorrado, this.fechaObjetivo);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (id != null) {
      map['id'] = id;
    }
    map['titulo'] = titulo;
    map['categoria'] = categoria;
    map['montoObjetivo'] = montoObjetivo;
    map['montoAhorrado'] = montoAhorrado;
    map['fechaObjetivo'] = fechaObjetivo;
    return map;
  }

  factory MetaAhorro.fromObject(dynamic o) => MetaAhorro.withId(
        o['id'],
        o['titulo'] ?? '',
        o['categoria'] ?? '',
        (o['montoObjetivo'] as num?)?.toDouble() ?? 0.0,
        (o['montoAhorrado'] as num?)?.toDouble() ?? 0.0,
        o['fechaObjetivo'] ?? '',
      );
}

/// Grupo de gastos compartidos (ej. "Asado Fin de Semana").
class Grupo {
  int? id; // null hasta persistir
  String nombre; // Nombre del grupo
  int integrantes; // Cantidad de personas
  int saldo; // + te deben | - debes | 0 saldado
  String icono; // Clave del icono (ej. 'asado', 'viaje', 'futbol', 'otro')

  // Constructor estandar: para grupos nuevos creados en la interfaz visual.
  Grupo(this.nombre, this.integrantes, this.saldo, this.icono, [this.id]);

  // Constructor nombrado: para grupos recuperados desde la base de datos.
  Grupo.withId(this.id, this.nombre, this.integrantes, this.saldo, this.icono);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (id != null) {
      map['id'] = id;
    }
    map['nombre'] = nombre;
    map['integrantes'] = integrantes;
    map['saldo'] = saldo;
    map['icono'] = icono;
    return map;
  }

  factory Grupo.fromObject(dynamic o) => Grupo.withId(
        o['id'],
        o['nombre'] ?? '',
        (o['integrantes'] as num?)?.toInt() ?? 0,
        (o['saldo'] as num?)?.toInt() ?? 0,
        o['icono'] ?? 'otro',
      );
}

/// Servicio o gasto fijo del hogar (ej. "Luz (Edemsa)").
class ServicioHogar {
  int? id; // null hasta persistir
  String titulo; // Nombre del servicio
  String detalle; // Detalle (ej. "Vence el 22/09 • Pendiente")
  double monto; // Monto del servicio
  int pagado; // 1 si esta pagado, 0 si esta pendiente

  // Constructor estandar: para servicios nuevos creados en la interfaz visual.
  ServicioHogar(this.titulo, this.detalle, this.monto, this.pagado, [this.id]);

  // Constructor nombrado: para servicios recuperados desde la base de datos.
  ServicioHogar.withId(
      this.id, this.titulo, this.detalle, this.monto, this.pagado);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (id != null) {
      map['id'] = id;
    }
    map['titulo'] = titulo;
    map['detalle'] = detalle;
    map['monto'] = monto;
    map['pagado'] = pagado;
    return map;
  }

  factory ServicioHogar.fromObject(dynamic o) => ServicioHogar.withId(
        o['id'],
        o['titulo'] ?? '',
        o['detalle'] ?? '',
        (o['monto'] as num?)?.toDouble() ?? 0.0,
        (o['pagado'] as num?)?.toInt() ?? 0,
      );
}

/// Entidad que representa un usuario de la aplicacion.
class Usuario {
  int? id; // Identificador del usuario (unico en el registro global)
  String nombre; // Nombre del usuario
  String email; // Correo electronico de la cuenta
  String password; // Contrasena de la cuenta

  // Constructor estandar: para usuarios nuevos (sin id asignado todavia).
  Usuario(this.nombre, this.email, this.password, [this.id]);

  // Constructor nombrado: para usuarios recuperados desde la base de datos.
  Usuario.withId(this.id, this.nombre, this.email, this.password);

  // Serializacion: Objeto Dart -> Map<String, dynamic> (fila de SQLite)
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (id != null) {
      map['id'] = id;
    }
    map['nombre'] = nombre;
    map['email'] = email;
    map['password'] = password;
    return map;
  }

  // Deserializacion: Map<String, dynamic> (fila de SQLite) -> Objeto Dart tipado
  factory Usuario.fromObject(dynamic o) => Usuario.withId(
        o['id'],
        o['nombre'] ?? '',
        o['email'] ?? '',
        o['password'] ?? '',
      );
}
