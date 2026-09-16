import 'package:flutter/material.dart';

class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          'Gastos del Hogar',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de aporte del hogar
            _buildBalanceSummaryCard(),
            const SizedBox(height: 20),

            // Miembros del Hogar
            const Text(
              'Integrantes del Hogar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildMembersList(),
            const SizedBox(height: 24),

            // Servicios y Gastos fijos
            const Text(
              'Servicios y Gastos Fijos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildServiceItem(
              title: 'Alquiler',
              sub: 'Vence el 10/10 • Pago compartido',
              amount: '\$220.000',
              isPaid: true,
            ),
            _buildServiceItem(
              title: 'Luz (Edemsa)',
              sub: 'Vence el 22/09 • Pendiente',
              amount: '\$18.400',
              isPaid: false,
            ),
            _buildServiceItem(
              title: 'Internet Fibra',
              sub: 'Vence el 28/09 • Pendiente',
              amount: '\$14.200',
              isPaid: false,
            ),
            _buildServiceItem(
              title: 'Gas',
              sub: 'Vence el 05/10 • Pendiente',
              amount: '\$9.800',
              isPaid: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Servicios y Hogar (Mes en curso)',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 6),
          const Text(
            '\$262.400',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniIndicator('Pagado', '\$220.000', Colors.green),
              _buildMiniIndicator('Pendiente', '\$42.400', Colors.orange),
              _buildMiniIndicator('Tu parte', '\$131.200', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniIndicator(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
        ),
      ],
    );
  }

  Widget _buildMembersList() {
    return SizedBox(
      height: 75,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildMemberAvatar('Vos', 'Al día', Colors.teal),
          _buildMemberAvatar('Juan', 'Al día', Colors.indigo),
          _buildMemberAvatar('Joaquín', 'Pendiente', Colors.deepOrange),
          _buildMemberAvatar('Tomás', 'Pendiente', Colors.blueGrey),
        ],
      ),
    );
  }

  Widget _buildMemberAvatar(String name, String status, Color color) {
    return Container(
      width: 75,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withAlpha(35),
            child: Text(
              name.substring(0, 1),
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              color: status == 'Al día' ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required String title,
    required String sub,
    required String amount,
    required bool isPaid,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          Icon(
            isPaid ? Icons.check_circle : Icons.schedule,
            color: isPaid ? Colors.green : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  sub,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}