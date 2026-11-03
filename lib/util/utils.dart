// Funciones puras de la aplicacion FinanzApp.
// Una funcion pura es determinista (la misma entrada siempre produce la misma
// salida) y no tiene efectos secundarios (no toca variables globales, UI ni
// persistencia). Por eso viven en una capa independiente de la UI y la BD.

import '../model/model.dart';

/// Valida y calcula cuantos dias faltan para la expiracion de un documento.
class ValidadorFecha {
  static int calcularDiasRestantes(DateTime fechaActual, DateTime fechaExpiracion) {
    // Retorna la diferencia en dias basandose unicamente en los parametros de entrada.
    return fechaExpiracion.difference(fechaActual).inDays;
  }

  // Compara SOLO el dia/mes/anio (ignora la hora) para que un movimiento
  // creado hoy no se considere vencido.
  static int diasEntreFechas(DateTime desde, DateTime hasta) {
    final DateTime a = DateTime(desde.year, desde.month, desde.day);
    final DateTime b = DateTime(hasta.year, hasta.month, hasta.day);
    return b.difference(a).inDays;
  }

  // Devuelve true si la fecha pertenece al mes indicado.
  static bool esMismaFecha(DateTime fecha, DateTime mes) {
    return fecha.year == mes.year && fecha.month == mes.month;
  }
}

/// Categorias disponibles para clasificar un gasto.
const List<String> categoriasGasto = <String>[
  'General',
  'Servicios',
  'Comida',
  'Transporte',
  'Entretenimiento',
  'Salud',
  'Educacion',
  'Otros',
];

/// Nombres de los meses (indice 1 -> Enero).
const List<String> _nombresMeses = <String>[
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

/// Nombre legible de un mes (1-12). Fuente unica: evita la logica duplicada
/// que existia en MainNavScreen y MonthScreen.
String nombreMes(int mes) {
  if (mes < 1 || mes > 12) {
    return '';
  }
  return _nombresMeses[mes - 1];
}

/// Etiqueta completa de un mes, ej. "Noviembre 2026".
String etiquetaMes(DateTime fecha) {
  return '${nombreMes(fecha.month)} ${fecha.year}';
}

/// Suma el monto de todos los gastos recibidos.
double totalGastos(List<Gasto> gastos) {
  double total = 0;
  for (final Gasto gasto in gastos) {
    total += gasto.monto;
  }
  return total;
}

/// Filtra los gastos que pertenecen al mes de la fecha indicada.
List<Gasto> gastosDelMes(List<Gasto> gastos, DateTime mes) {
  return gastos
      .where((Gasto gasto) =>
          ValidadorFecha.esMismaFecha(DateTime.tryParse(gasto.expiration) ?? DateTime(0), mes))
      .toList(growable: false);
}

/// Filtra los ingresos que pertenecen al mes de la fecha indicada.
List<Ingreso> ingresosDelMes(List<Ingreso> ingresos, DateTime mes) {
  return ingresos
      .where((Ingreso ingreso) =>
          ValidadorFecha.esMismaFecha(DateTime.tryParse(ingreso.fecha) ?? DateTime(0), mes))
      .toList(growable: false);
}

/// Suma el monto de todos los ingresos recibidos.
double totalIngresos(List<Ingreso> ingresos) {
  double total = 0;
  for (final Ingreso ingreso in ingresos) {
    total += ingreso.monto;
  }
  return total;
}

/// Suma lo acumulado en todas las metas de ahorro.
double totalAhorrado(List<MetaAhorro> metas) {
  double total = 0;
  for (final MetaAhorro meta in metas) {
    total += meta.montoAhorrado;
  }
  return total;
}

/// Agrupa los gastos sumando el monto por categoria.
/// Devuelve un mapa sin orden garantizado; el llamador decide como ordenarlo.
Map<String, double> gastosPorCategoria(List<Gasto> gastos) {
  final Map<String, double> acumulado = <String, double>{};
  for (final Gasto gasto in gastos) {
    final String categoria = gasto.categoria.isEmpty ? 'Sin categoria' : gasto.categoria;
    acumulado[categoria] = (acumulado[categoria] ?? 0) + gasto.monto;
  }
  return acumulado;
}

/// Devuelve las categorias ordenadas de mayor a menor monto.
List<MapEntry<String, double>> categoriasOrdenadas(List<Gasto> gastos) {
  final List<MapEntry<String, double>> entradas =
      gastosPorCategoria(gastos).entries.toList(growable: false);
  entradas.sort((a, b) => b.value.compareTo(a.value));
  return entradas;
}

/// Porcentaje (0.0 - 1.0) de una parte sobre un total. Total 0 -> 0.0.
double porcentaje(double parte, double total) {
  if (total <= 0) {
    return 0;
  }
  final double resultado = parte / total;
  if (resultado < 0) {
    return 0;
  }
  if (resultado > 1) {
    return 1;
  }
  return resultado;
}

/// Progreso (0.0 - 1.0) de una meta de ahorro.
double progresoMeta(MetaAhorro meta) {
  return porcentaje(meta.montoAhorrado, meta.montoObjetivo);
}

/// Formatea un monto numerico a su representacion monetaria.
String formatearMoneda(double monto) {
  return '\$${monto.toStringAsFixed(0)}';
}

/// Formatea una fecha guardada como String en formato YYYY-MM-DD a una forma legible (DD/MM/AAAA).
String formatearFecha(String fechaExpiracion) {
  if (fechaExpiracion.length != 10) {
    return fechaExpiracion;
  }
  return '${fechaExpiracion.substring(8, 10)}/${fechaExpiracion.substring(5, 7)}/${fechaExpiracion.substring(0, 4)}';
}

/// Devuelve la fecha de hoy en formato YYYY-MM-DD.
String fechaHoy() {
  final DateTime ahora = DateTime.now();
  final String mes = ahora.month.toString().padLeft(2, '0');
  final String dia = ahora.day.toString().padLeft(2, '0');
  return '${ahora.year}-$mes-$dia';
}
