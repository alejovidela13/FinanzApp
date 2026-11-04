import 'package:flutter/material.dart';

import '../data/gasto_repository.dart';
import '../data/ingreso_repository.dart';
import '../data/meta_ahorro_repository.dart';
import '../model/model.dart';
import '../util/utils.dart';
import 'add_expense_sheet.dart';

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
      _recargar();
    }
  }

  // Abre el mismo dialogo en modo edicion sobre un ingreso existente.
  Future<void> _editarIngreso(Ingreso ingreso) async {
    final bool? guardado = await showDialog<bool>(
      context: context,
      builder: (context) => _DialogoIngreso(ingreso: ingreso),
    );
    if (guardado == true && mounted) {
      _recargar();
    }
  }

  // Elimina un ingreso tras confirmar con el usuario.
  Future<void> _eliminarIngreso(Ingreso ingreso) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ingreso'),
        content: Text('¿Eliminar "${ingreso.concepto}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) {
      return;
    }
    await IngresoRepository().deleteIngreso(ingreso.id!);
    if (mounted) {
      _recargar();
    }
  }

  // Elimina un gasto tras confirmar con el usuario.
  Future<void> _eliminarGasto(Gasto gasto) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Eliminar "${gasto.concepto}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) {
      return;
    }
    await GastoRepository().deleteGasto(gasto.id!);
    if (mounted) {
      _recargar();
    }
  }

  // Abre la hoja de alta/edicion de gastos y recarga al volver.
  Future<void> _abrirGasto({Gasto? gasto}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddExpenseSheet(gasto: gasto),
    );
    if (mounted) {
      _recargar();
    }
  }

  // Vuelve a pedir los datos a los repositorios y reconstruye la pantalla.
  void _recargar() {
    // La carga arranca antes del setState: el callback de setState tiene
    // que ser sincrono (no puede devolver un Future).
    final Future<_DatosInicio> futuro = _cargarDatos();
    setState(() {
      _datosFuture = futuro;
    });
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
    final double saldo = saldoTotal(gastos, datos.ingresos, datos.metas);
    final List<MapEntry<String, double>> categorias = categoriasOrdenadas(gastosMes);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Tarjeta principal: cuanta plata hay disponible hoy.
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF232526), Color(0xFF414345)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saldo total',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                formatearMoneda(saldo),
                style: TextStyle(
                  color: saldo >= 0 ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                saldo >= 0
                    ? 'Plata que tenés disponible para gastar'
                    : 'Gastaste más de lo que ingresó',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Text(
                'Ingresos ${formatearMoneda(totalIngresos(datos.ingresos))} '
                '• Gastos ${formatearMoneda(totalGastos(gastos))} '
                '• Ahorros ${formatearMoneda(ahorroTotal)}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tarjeta de gastos del mes calculados desde SQLite.
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

        // Alta de ingresos: permite cargar lo que el usuario quiera.
        OutlinedButton.icon(
          onPressed: _agregarIngreso,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Agregar ingreso'),
        ),

        // Lista de ingresos del mes: cada item permite editar o eliminar.
        // Solo se muestra cuando la cuenta tiene ingresos cargados.
        if (datos.ingresos.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSeccionIngresos(datos.ingresos),
        ],

        const SizedBox(height: 24),

        // Lista de gastos entregada dinamicamente por el repositorio.
        // El total y la cantidad ya los muestra la tarjeta de arriba.
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

        const SizedBox(height: 24),

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
      ],
    );
  }
  Widget _buildSeccionIngresos(List<Ingreso> todos) {
    final List<Ingreso> ingresosMes = ingresosDelMes(todos, DateTime.now());

    return Container(
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
              Icon(Icons.trending_up, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Ingresos del mes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Total ${formatearMoneda(totalIngresos(ingresosMes))} • ${ingresosMes.length} registro(s)',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (ingresosMes.isEmpty)
            const Text(
              'Aun no hay ingresos este mes.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          else
            ...ingresosMes.map((Ingreso ingreso) => _buildIngresoItem(ingreso)),
        ],
      ),
    );
  }

  // Item visual de cada ingreso, con menu de acciones.
  Widget _buildIngresoItem(Ingreso ingreso) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.shade100,
            child: const Icon(Icons.attach_money, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingreso.concepto,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  formatearFecha(ingreso.fecha),
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '+${formatearMoneda(ingreso.monto)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green,
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            onSelected: (String accion) {
              if (accion == 'editar') {
                _editarIngreso(ingreso);
              } else if (accion == 'eliminar') {
                _eliminarIngreso(ingreso);
              }
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(value: 'editar', child: Text('Editar')),
              PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
    );
  }

  // Barra apilada: representa el peso de cada categoria sobre el gasto total.
  Widget _buildBarraCategorias(List<MapEntry<String, double>> categorias) {
    final double total = categorias.fold<double>(0, (sum, e) => sum + e.value);

    // Sin categorias, o con un total en cero/negativo (posible cuando hay
    // devoluciones de grupo registradas como gasto negativo), no hay
    // proporciones que repartir.
    if (categorias.isEmpty || total <= 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 8,
          color: Colors.white24,
        ),
      );
    }

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
      // Tocar el gasto abre su edicion; el menu ofrece editar o eliminar.
      child: InkWell(
        onTap: () => _abrirGasto(gasto: gasto),
        borderRadius: BorderRadius.circular(12),
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
                  '${gasto.categoria} • ${formatearFecha(gasto.expiration)}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            formatearMoneda(gasto.monto),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            onSelected: (String accion) {
              if (accion == 'editar') {
                _abrirGasto(gasto: gasto);
              } else if (accion == 'eliminar') {
                _eliminarGasto(gasto);
              }
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(value: 'editar', child: Text('Editar')),
              PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
            ],
          ),
        ],
        ),
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

// Dialogo de alta y edicion de ingresos (concepto + monto + fecha).
class _DialogoIngreso extends StatefulWidget {
  // Ingreso a editar. Null -> modo alta.
  final Ingreso? ingreso;

  const _DialogoIngreso({this.ingreso});

  @override
  State<_DialogoIngreso> createState() => _DialogoIngresoState();
}

class _DialogoIngresoState extends State<_DialogoIngreso> {
  final _formKey = GlobalKey<FormState>();
  final _conceptoController = TextEditingController();
  final _montoController = TextEditingController();
  late DateTime _fecha;

  bool get _esEdicion => widget.ingreso != null;

  @override
  void initState() {
    super.initState();
    final Ingreso? ingreso = widget.ingreso;
    if (ingreso != null) {
      _conceptoController.text = ingreso.concepto;
      _montoController.text = ingreso.monto.toStringAsFixed(2);
      _fecha = DateTime.tryParse(ingreso.fecha) ?? DateTime.now();
    } else {
      _fecha = DateTime.now();
    }
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  String _aTextoFecha(DateTime fecha) {
    final String mes = fecha.month.toString().padLeft(2, '0');
    final String dia = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }

  Future<void> _elegirFecha() async {
    final DateTime? seleccionada = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (seleccionada != null) {
      setState(() => _fecha = seleccionada);
    }
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
      _aTextoFecha(_fecha),
      widget.ingreso?.id,
    );
    if (_esEdicion) {
      await IngresoRepository().updateIngreso(ingreso);
    } else {
      await IngresoRepository().addIngreso(ingreso);
    }
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? 'Editar ingreso' : 'Agregar ingreso'),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresá el monto';
                  }
                  final double? monto =
                      double.tryParse(value.replaceAll(',', '.'));
                  if (monto == null || monto <= 0) {
                    return 'Ingresá un monto mayor a cero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _elegirFecha,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(formatearFecha(_aTextoFecha(_fecha))),
                ),
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
          child: Text(_esEdicion ? 'Guardar cambios' : 'Guardar'),
        ),
      ],
    );
  }
}
