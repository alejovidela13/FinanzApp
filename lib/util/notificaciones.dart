// Notificaciones REALES de FinanzApp.
//
// A diferencia de la version anterior (lista fija de mensajes), estas
// notificaciones se calculan en el momento a partir de los datos del usuario:
// servicios del hogar sin pagar y metas de ahorro.
//
// Los gastos NO generan alertas: un gasto es plata que ya salio, no algo que
// venza. Su fecha sirve para ordenarlos y agruparlos por mes.
//
// Las funciones son puras: reciben los datos y devuelven la lista, sin tocar
// la base de datos ni la interfaz. Asi se pueden testear por separado.

import '../model/model.dart';
import 'utils.dart';

/// Categorias de notificacion (determinan el color y el orden).
enum TipoNotificacion {
  /// Servicio del hogar todavia sin pagar.
  pendiente,

  /// Meta de ahorro: alcanzada, vencida o por vencer.
  meta,
}

/// Notificacion generada a partir de los datos reales de la cuenta.
class Notificacion {
  final String titulo;
  final String detalle;
  final String tiempo; // Etiqueta corta: "Pendiente", "En 5 dias"...
  final TipoNotificacion tipo;
  final int prioridad; // 0 = urgente, 3 = informativo

  const Notificacion({
    required this.titulo,
    required this.detalle,
    required this.tiempo,
    required this.tipo,
    required this.prioridad,
  });
}

/// Dias dentro de los cuales una meta genera alerta por fecha objetivo.
const int _ventanaAlertaDias = 30;

/// Genera la lista de notificaciones a partir de los datos de la cuenta.
/// Devuelve las mas urgentes primero.
List<Notificacion> generarNotificaciones({
  required List<ServicioHogar> servicios,
  required List<MetaAhorro> metas,
  DateTime? hoy,
}) {
  final DateTime fecha = hoy ?? DateTime.now();
  final List<Notificacion> lista = <Notificacion>[];

  // ---------------------------------------------------------------
  // SERVICIOS DEL HOGAR: los que siguen pendientes de pago.
  // ---------------------------------------------------------------
  for (final ServicioHogar servicio in servicios) {
    if (servicio.pagado == 1) {
      continue;
    }
    final String detalle = servicio.detalle.isEmpty
        ? '${servicio.titulo} • ${formatearMoneda(servicio.monto)} pendiente de pago'
        : '${servicio.titulo} • ${servicio.detalle} (${formatearMoneda(servicio.monto)})';
    lista.add(Notificacion(
      titulo: 'Servicio pendiente',
      detalle: detalle,
      tiempo: 'Pendiente',
      tipo: TipoNotificacion.pendiente,
      prioridad: 2,
    ));
  }

  // ---------------------------------------------------------------
  // METAS DE AHORRO: alcanzadas, vencidas o por vencer.
  // ---------------------------------------------------------------
  for (final MetaAhorro meta in metas) {
    final DateTime objetivo = DateTime.tryParse(meta.fechaObjetivo) ?? fecha;
    final int dias = ValidadorFecha.diasEntreFechas(fecha, objetivo);
    final bool completa = meta.montoAhorrado >= meta.montoObjetivo;

    if (completa) {
      lista.add(Notificacion(
        titulo: 'Meta alcanzada',
        detalle: '${meta.titulo} • juntaste ${formatearMoneda(meta.montoAhorrado)}',
        tiempo: '¡Logrado!',
        tipo: TipoNotificacion.meta,
        prioridad: 3,
      ));
    } else if (dias < 0) {
      final double falta = meta.montoObjetivo - meta.montoAhorrado;
      lista.add(Notificacion(
        titulo: 'Meta vencida',
        detalle:
            '${meta.titulo} • pasó la fecha objetivo y faltan ${formatearMoneda(falta)}',
        tiempo: 'Vencido',
        tipo: TipoNotificacion.meta,
        prioridad: 1,
      ));
    } else if (dias <= _ventanaAlertaDias) {
      final int porcentaje = (progresoMeta(meta) * 100).round();
      lista.add(Notificacion(
        titulo: 'Fecha objetivo próxima',
        detalle:
            '${meta.titulo} • vence el ${formatearFecha(meta.fechaObjetivo)} y vas por $porcentaje%',
        tiempo: dias == 0 ? 'Hoy' : 'En $dias días',
        tipo: TipoNotificacion.meta,
        prioridad: 2,
      ));
    }
  }

  // Orden: primero lo urgente; dentro de cada prioridad se mantiene el
  // orden en que se cargaron (servicios, metas).
  lista.sort((a, b) => a.prioridad.compareTo(b.prioridad));
  return lista;
}
