import 'package:flutter/material.dart';

class MonthScreen extends StatelessWidget {
  const MonthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text(
          'Gastos del Mes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de mes interactivo
            _buildMonthSelector(),
            const SizedBox(height: 16),

            // Tarjeta de Resumen Mensual
            _buildTotalCard(),
            const SizedBox(height: 24),

            // Título de sección Desglose
            const Text(
              'Desglose por Categoría',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Lista de categorías con barra de progreso
            _buildCategoryItem(
              icon: Icons.shopping_bag_outlined,
              color: Colors.orange,
              name: 'Supermercado y Compras',
              amount: '\$145.000',
              percentage: 0.45,
            ),
            _buildCategoryItem(
              icon: Icons.home_outlined,
              color: Colors.blue,
              name: 'Servicios e Impuestos',
              amount: '\$82.500',
              percentage: 0.25,
            ),
            _buildCategoryItem(
              icon: Icons.directions_car_outlined,
              color: Colors.teal,
              name: 'Transporte y Combustible',
              amount: '\$48.200',
              percentage: 0.15,
            ),
            _buildCategoryItem(
              icon: Icons.local_dining_outlined,
              color: Colors.purple,
              name: 'Salidas y Ocio',
              amount: '\$33.100',
              percentage: 0.10,
            ),
          ],
        ),
      ),
    );
  }

  // Widget selector de mes (flechas izquierda/derecha)
  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 16),
            onPressed: () {},
          ),
          const Text(
            'Septiembre 2026',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // Tarjeta resumen del total gastado
  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Gastado en el Período',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            '\$308.800',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Presupuesto mensual restante: \$91.200',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Ítem de categoría con barra de progreso
  Widget _buildCategoryItem({
    required IconData icon,
    required Color color,
    required String name,
    required String amount,
    required double percentage,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Text(
                amount,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}