import 'package:flutter/material.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          'Juntadas y Grupos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de Deudas y Cobros
            _buildBalanceHeader(),
            const SizedBox(height: 20),

            // Grupos Activos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grupos Activos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _buildGroupCard(
              title: 'Asado Fin de Semana',
              membersCount: 6,
              statusText: 'Te deben \$8.500',
              statusColor: Colors.green,
              icon: Icons.outdoor_grill_outlined,
            ),
            _buildGroupCard(
              title: 'Viaje a la Costa',
              membersCount: 4,
              statusText: 'Debés \$12.400',
              statusColor: Colors.redAccent,
              icon: Icons.beach_access_outlined,
            ),
            _buildGroupCard(
              title: 'Fútbol de los Jueves',
              membersCount: 10,
              statusText: 'Todo saldado',
              statusColor: Colors.grey,
              icon: Icons.sports_soccer_outlined,
            ),
            const SizedBox(height: 24),

            // Últimos Movimientos Compartidos
            const Text(
              'Actividad Reciente',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildRecentActivityItem(
              user: 'Joaquín',
              action: 'pagó Bebidas y Hielo',
              group: 'Asado Fin de Semana',
              amount: '\$18.000',
            ),
            _buildRecentActivityItem(
              user: 'Vos',
              action: 'pagaste Cancha y Luz',
              group: 'Fútbol de los Jueves',
              amount: '\$25.000',
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta de balance general (lo que debés vs lo que te deben)
  Widget _buildBalanceHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Te deben en total',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                SizedBox(height: 4),
                Text(
                  '+\$8.500',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.shade300,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Tenés que pagar',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                SizedBox(height: 4),
                Text(
                  '-\$12.400',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta de grupo individual
  Widget _buildGroupCard({
    required String title,
    required int membersCount,
    required String statusText,
    required Color statusColor,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF1E3C72).withAlpha(20),
            child: Icon(icon, color: const Color(0xFF1E3C72)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '$membersCount integrantes',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            statusText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // Ítem de actividad reciente
  Widget _buildRecentActivityItem({
    required String user,
    required String action,
    required String group,
    required String amount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 20, color: Colors.black45),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13),
                children: [
                  TextSpan(
                    text: '$user ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: '$action en '),
                  TextSpan(
                    text: group,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}