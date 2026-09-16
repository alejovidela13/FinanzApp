import 'package:flutter/material.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          'Metas de Ahorro',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen General de Ahorro
            _buildTotalSavingsCard(),
            const SizedBox(height: 20),

            // Metas Activas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tus Metas Activas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva meta'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _buildGoalCard(
              title: 'Vacaciones de Verano',
              category: 'Viajes',
              savedAmount: 480000,
              targetAmount: 800000,
              color: Colors.teal,
              icon: Icons.flight_takeoff_outlined,
            ),
            _buildGoalCard(
              title: 'Fondo de Emergencia',
              category: 'Seguridad',
              savedAmount: 350000,
              targetAmount: 500000,
              color: Colors.indigo,
              icon: Icons.shield_outlined,
            ),
            _buildGoalCard(
              title: 'Nueva Bicicleta',
              category: 'Deportes',
              savedAmount: 120000,
              targetAmount: 280000,
              color: Colors.amber.shade800,
              icon: Icons.pedal_bike_outlined,
            ),
            const SizedBox(height: 20),

            // Consejos o Tips de Ahorro
            _buildTipCard(),
          ],
        ),
      ),
    );
  }

  // Tarjeta de total acumulado
  Widget _buildTotalSavingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Total acumulado en metas',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          SizedBox(height: 8),
          Text(
            '\$950.000',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Meta global: \$1.580.000 (60% completado)',
            style: TextStyle(color: Colors.tealAccent, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Tarjeta para cada objetivo individual
  Widget _buildGoalCard({
    required String title,
    required String category,
    required double savedAmount,
    required double targetAmount,
    required Color color,
    required IconData icon,
  }) {
    final progress = (savedAmount / targetAmount).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(25),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      category,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ahorrado: \$${savedAmount.toInt()}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                'Objetivo: \$${targetAmount.toInt()}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tarjeta de recomendación
  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        children: const [
          Icon(Icons.lightbulb_outline, color: Colors.teal, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aportando \$15.000 extra por semana podés alcanzar tu meta de vacaciones 1 mes antes.',
              style: TextStyle(fontSize: 12, color: Colors.teal),
            ),
          ),
        ],
      ),
    );
  }
}