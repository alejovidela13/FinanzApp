import 'package:flutter/material.dart';

import '../data/gasto_repository.dart';
import '../data/ingreso_repository.dart';
import '../data/meta_ahorro_repository.dart';
import '../model/model.dart';
import '../util/utils.dart';

// Datos que consume la pantalla de inicio, cargados todos juntos desde los
// repositorios para mostrar un unico estado coherente.
class _DatosInicio {
  final List<Gasto> gastos;
  final List<Ingreso> ingresos;
  final List<MetaAhorro> metas;

  const _DatosInicio(this.gastos, this.ingresos, this.metas);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_DatosInicio> _datosFuture;

  // Paleta estable para distinguir las categorias en el grafico.
  static const List<Color> _colores = <Color>[
    Color(0xFF4C68FF),
    Color(0xFFFFA726),
    Color(0xFF26A69A),
    Color(0xFFEC407A),
    Color(0xFF7E57C2),
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
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Al reconstruirse la pantalla (ej. tras agregar un gasto), se recarga
    // la informacion directamente de los repositorios.
    _datosFuture = _cargarDatos();
  }

  Future<_DatosInicio> _cargarDatos() async {
    final List<Gasto> gastos = await GastoRepository().getGastos();
    final List<Ingreso> ingresos = await IngresoRepository().getIngresos();
    final List<MetaAhorro> metas = await MetaAhorroRepository().getMetas();
    return _DatosInicio(gastos, ingresos, metas);
  }

  // Abre un dialogo para cargar un ingreso nuevo.
  Future<void> _agregarIngreso() async {
    final bool? guardado = await showDialog<bool>(
      context: context,
      builder: (context) => const _DialogoIngreso(),
    );
    if (guardado == true && mounted) {
      // La carga arranca antes del setState: el callback de setState tiene
      // que ser sincrono (no puede devolver un Future).
      final Future<_DatosInicio> futuro = _cargarDatos();
      setState(() {
        _datosFuture = futuro;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DatosInicio>(
      future: _datosFuture,
      builder: (context, snapshot) {
        final _DatosInicio datos =
            snapshot.data ?? const _DatosInicio(<Gasto>[], <Ingreso>[], <MetaAhorro>[]);
        return _buildLista(datos);
      },
    );
  }

  Widget _buildLista(_DatosInicio datos) {
    final List<Gasto> gastos = datos.gastos;
    final DateTime hoy = DateTime.now();
    final List<Gasto> gastosMes = gastosDelMes(gastos, hoy);
    final double totalMes = totalGastos(gastosMes);
    final double totalIngresosMes = totalIngresos(ingresosDelMes(datos.ingresos, hoy));
    final double ahorroTotal = totalAhorrado(datos.metas);
    final List<MapEntry<String, double>> categorias = categoriasOrdenadas(gastosMes);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Tarjeta principal: gastos del mes calculados desde SQLite.
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF4C68FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gastos del mes',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    etiquetaMes(hoy),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatearMoneda(totalMes),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Gastos', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        '${gastosMes.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                gastosMes.isEmpty
                    ? 'Sin gastos registrados este mes'
                    : '${gastosMes.length} gasto(s) registrado(s) en ${etiquetaMes(hoy)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _buildBarraCategorias(categorias),
              const SizedBox(height: 8),
              _buildLeyendaCategorias(categorias),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Fila de 3 tarjetas: valores reales (ingresos, ahorros y gastos).
        Row(
          children: [
            _buildMetricCard(
              icon: Icons.trending_up,
              label: 'Ingresos',
              amount: formatearMoneda(totalIngresosMes),
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            _buildMetricCard(
              icon: Icons.savings_outlined,
              label: 'Ahorros',
              amount: formatearMoneda(ahorroTotal),
              color: Colors.amber,
            ),
            const SizedBox(width: 8),
            _buildMetricCard(
              icon: Icons.trending_down,
              label: 'Gastos',
              amount: formatearMoneda(totalMes),
              color: Colors.red,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Alta de ingresos: permite cargar lo que el usuario quiera.
        OutlinedButton.icon(
          onPressed: _agregarIngreso,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Agregar ingreso'),
        ),

        const SizedBox(height: 24),

        // Seccion Gastos del mes: construida a partir de los datos reales.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.bar_chart, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text(
                    'Gastos del mes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Total ${formatearMoneda(totalMes)} • ${gastosMes.length} registro(s)',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Lista de gastos entregada dinamicamente por el repositorio.
        if (gastosMes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Aun no hay gastos registrados.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          )
        else
          ...gastosMes.map((Gasto gasto) => _buildGastoItem(gasto)),
      ],
    );
  }

  // Barra apilada: representa el peso de cada categoria sobre el gasto total.
  Widget _buildBarraCategorias(List<MapEntry<String, double>> categorias) {
    if (categorias.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 8,
          color: Colors.white24,
        ),
      );
    }

    final double total = categorias.fold<double>(0, (sum, e) => sum + e.value);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            for (int i = 0; i < categorias.length; i++)
              Expanded(
                flex: (categorias[i].value / total * 1000).round().clamp(1, 1000),
                child: Container(color: _colores[i % _colores.length]),
              ),
          ],
        ),
      ),
    );
  }

  // Leyenda de la barra: las tres categorias con mayor gasto.
  Widget _buildLeyendaCategorias(List<MapEntry<String, double>> categorias) {
    if (categorias.isEmpty) {
      return const Text(
        'Sin gastos para mostrar',
        style: TextStyle(color: Colors.white70, fontSize: 11),
      );
    }

    final int hasta = categorias.length > 3 ? 3 : categorias.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < hasta; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _colores[i % _colores.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    categorias[i].key,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
                Text(
                  formatearMoneda(categorias[i].value),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        if (categorias.length > 3)
          Text(
            '+${categorias.length - 3} categoria(s) más',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
      ],
    );
  }

  // Item visual de cada gasto obtenido del repositorio.
  Widget _buildGastoItem(Gasto gasto) {
    final DateTime fechaExpiracion =
        DateTime.tryParse(gasto.expiration) ?? DateTime.now();
    final int diasRestantes =
        ValidadorFecha.diasEntreFechas(DateTime.now(), fechaExpiracion);

    final String textoVencimiento;
    final Color colorVencimiento;
    if (diasRestantes > 0) {
      textoVencimiento = 'Expira en $diasRestantes días';
      colorVencimiento = Colors.green;
    } else if (diasRestantes == 0) {
      textoVencimiento = 'Vence hoy';
      colorVencimiento = Colors.orange;
    } else {
      textoVencimiento = 'Vencido';
      colorVencimiento = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            backgroundColor: Colors.amber.shade100,
            child: const Icon(Icons.receipt_long_outlined, color: Colors.amber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gasto.concepto,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${gasto.categoria} • Vence el ${formatearFecha(gasto.expiration)}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatearMoneda(gasto.monto),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                textoVencimiento,
                style: TextStyle(color: colorVencimiento, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String amount,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              amount,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// Dialogo de alta de ingresos (concepto + monto).
class _DialogoIngreso extends StatefulWidget {
  const _DialogoIngreso();

  @override
  State<_DialogoIngreso> createState() => _DialogoIngresoState();
}

class _DialogoIngresoState extends State<_DialogoIngreso> {
  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _montoController = TextEditingController();

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final double monto =
        double.tryParse(_montoController.text.replaceAll(',', '.')) ?? 0;
    final Ingreso ingreso = Ingreso(
      _conceptoController.text.trim(),
      monto,
      fechaHoy(),
    );
    await IngresoRepository().addIngreso(ingreso);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar ingreso'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _conceptoController,
                decoration: const InputDecoration(
                  labelText: 'Concepto',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Ingresá un concepto'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Ingresá el monto' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
