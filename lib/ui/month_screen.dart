import 'package:flutter/material.dart';

import '../data/gasto_repository.dart';
import '../data/ingreso_repository.dart';
import '../model/model.dart';
import '../util/utils.dart';

// Datos del periodo cargados desde los repositorios.
class _DatosMes {
  final List<Gasto> gastos;
  final List<Ingreso> ingresos;

  const _DatosMes(this.gastos, this.ingresos);
}

class MonthScreen extends StatefulWidget {
  const MonthScreen({super.key});

  @override
  State<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends State<MonthScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late Future<_DatosMes> _datosFuture;

  static const List<Color> _colores = <Color>[
    Color(0xFFFFA726),
    Color(0xFF4C68FF),
    Color(0xFF26A69A),
    Color(0xFF7E57C2),
    Color(0xFFEC407A),
    Color(0xFF66BB6A),
    Color(0xFF29B6F6),
    Color(0xFF8D6E63),
  ];

  @override
  void initState() {
    super.initState();
    _datosFuture = _cargarDatos();
  }

  @override
  void didUpdateWidget(covariant MonthScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _datosFuture = _cargarDatos();
  }

  Future<_DatosMes> _cargarDatos() async {
    final List<Gasto> gastos = await GastoRepository().getGastos();
    final List<Ingreso> ingresos = await IngresoRepository().getIngresos();
    return _DatosMes(gastos, ingresos);
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    });
  }

  // Abre el selector de fecha para elegir el mes a mostrar.
  Future<void> _elegirMes() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _currentMonth,
      firstDate: DateTime(2000, 1),
      lastDate: DateTime(2100, 12),
    );
    if (fecha != null && mounted) {
      setState(() => _currentMonth = DateTime(fecha.year, fecha.month, 1));
    }
  }

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
            tooltip: 'Elegir mes',
            onPressed: _elegirMes,
          ),
        ],
      ),
      body: FutureBuilder<_DatosMes>(
        future: _datosFuture,
        builder: (context, snapshot) {
          final _DatosMes datos =
              snapshot.data ?? const _DatosMes(<Gasto>[], <Ingreso>[]);
          return _buildContenido(datos);
        },
      ),
    );
  }

  Widget _buildContenido(_DatosMes datos) {
    final List<Gasto> gastosMes = gastosDelMes(datos.gastos, _currentMonth);
    final double totalGastado = totalGastos(gastosMes);
    final double totalIngresado =
        totalIngresos(ingresosDelMes(datos.ingresos, _currentMonth));
    final double balance = totalIngresado - totalGastado;
    final List<MapEntry<String, double>> categorias = categoriasOrdenadas(gastosMes);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de mes interactivo
          _buildMonthSelector(),
          const SizedBox(height: 16),

          // Tarjeta de resumen del periodo (valores reales)
          _buildTotalCard(totalGastado, totalIngresado, balance),
          const SizedBox(height: 24),

          // Desglose por categoria calculado desde SQLite
          const Text(
            'Desglose por Categoría',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (categorias.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sin gastos en este período.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            for (int i = 0; i < categorias.length; i++)
              _buildCategoryItem(
                icon: _iconoDe(categorias[i].key),
                color: _colores[i % _colores.length],
                name: categorias[i].key,
                amount: formatearMoneda(categorias[i].value),
                percentage: porcentaje(categorias[i].value, totalGastado),
              ),
        ],
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
            color: Colors.black.withValues(alpha: 0.04),
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
            tooltip: 'Mes anterior',
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            etiquetaMes(_currentMonth),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            tooltip: 'Mes siguiente',
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  // Tarjeta resumen con gastado, ingresado y balance del periodo.
  Widget _buildTotalCard(double totalGastado, double totalIngresado, double balance) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Gastado en el Período',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            formatearMoneda(totalGastado),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ingresos: ${formatearMoneda(totalIngresado)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Balance: ${formatearMoneda(balance)}',
            style: TextStyle(
              color: balance >= 0 ? Colors.greenAccent : Colors.redAccent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Ítem de categoría con barra de progreso.
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
            color: Colors.black.withValues(alpha: 0.03),
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
                backgroundColor: color.withValues(alpha: 0.12),
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
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(percentage * 100).round()}%',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // Icono representativo para cada categoria de gasto.
  IconData _iconoDe(String categoria) {
    switch (categoria) {
      case 'Servicios':
        return Icons.home_outlined;
      case 'Comida':
        return Icons.local_dining_outlined;
      case 'Transporte':
        return Icons.directions_car_outlined;
      case 'Entretenimiento':
        return Icons.movie_outlined;
      case 'Salud':
        return Icons.favorite_outline;
      case 'Educacion':
        return Icons.school_outlined;
      case 'Otros':
        return Icons.category_outlined;
      default:
        return Icons.shopping_bag_outlined;
    }
  }
}
