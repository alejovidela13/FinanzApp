import 'package:flutter/material.dart';

import '../data/meta_ahorro_repository.dart';
import '../data/servicio_hogar_repository.dart';
import '../model/model.dart';
import '../util/notificaciones.dart';

// Pantalla de notificaciones con alertas REALES de la cuenta:
// se calcula al abrirla a partir de los servicios pendientes y las metas
// guardados en SQLite (no hay mensajes fijos).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Notificacion>> _notificacionesFuture;

  @override
  void initState() {
    super.initState();
    _notificacionesFuture = _cargar();
  }

  // Lee los datos de la cuenta y los convierte en notificaciones.
  Future<List<Notificacion>> _cargar() async {
    final List<ServicioHogar> servicios =
        await ServicioHogarRepository().getServicios();
    final List<MetaAhorro> metas = await MetaAhorroRepository().getMetas();
    return generarNotificaciones(
      servicios: servicios,
      metas: metas,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Notificacion>>(
        future: _notificacionesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Notificacion> notificaciones =
              snapshot.data ?? <Notificacion>[];

          if (notificaciones.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none,
                        size: 56, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No hay notificaciones por ahora.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Te avisamos cuando un servicio quede pendiente o se acerque la fecha de una meta.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: notificaciones.length,
            separatorBuilder: (context, index) => const Divider(height: 20),
            itemBuilder: (context, index) {
              final Notificacion notificacion = notificaciones[index];
              final _EstiloNotificacion estilo =
                  _estilos[notificacion.tipo] ?? _estilos[TipoNotificacion.pendiente]!;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: estilo.fondo,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(estilo.icono, color: estilo.color),
                ),
                title: Text(
                  notificacion.titulo,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  notificacion.detalle,
                  style:
                      const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                trailing: Text(
                  notificacion.tiempo,
                  style: TextStyle(fontSize: 12, color: estilo.color),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Presentacion de cada tipo de notificacion.
class _EstiloNotificacion {
  final IconData icono;
  final Color color;
  final Color fondo;

  const _EstiloNotificacion(this.icono, this.color, this.fondo);
}

const Map<TipoNotificacion, _EstiloNotificacion> _estilos =
    <TipoNotificacion, _EstiloNotificacion>{
  TipoNotificacion.pendiente: _EstiloNotificacion(
      Icons.receipt_long_outlined, Colors.blue, Color(0xFFE3F2FD)),
  TipoNotificacion.meta: _EstiloNotificacion(
      Icons.track_changes, Colors.teal, Color(0xFFE0F2F1)),
};
