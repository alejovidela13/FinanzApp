import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const List<Map<String, String>> _notifications = [
    {
      'title': 'Pago confirmado',
      'body': 'Joaquín pagó Cancha y Luz por \$25.000',
      'time': 'Hoy',
    },
    {
      'title': 'Deuda actualizada',
      'body': 'Te deben \$8.500 en el Asado Fin de Semana',
      'time': 'Hoy',
    },
    {
      'title': 'Nuevo integrante',
      'body': 'Tomás se sumó al Fútbol de los Jueves',
      'time': 'Ayer',
    },
  ];

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
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 20),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_outlined, color: Colors.amber),
            ),
            title: Text(
              notification['title']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              notification['body']!,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            trailing: Text(
              notification['time']!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
