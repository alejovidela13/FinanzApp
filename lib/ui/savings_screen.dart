import 'package:flutter/material.dart';

import '../data/meta_ahorro_repository.dart';
import '../model/model.dart';
import '../util/utils.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  late Future<List<MetaAhorro>> _metasFuture;

  @override
  void initState() {
    super.initState();
    _metasFuture = _cargarMetas();
  }

  @override
  void didUpdateWidget(covariant SavingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _metasFuture = _cargarMetas();
  }

  Future<List<MetaAhorro>> _cargarMetas() {
    return MetaAhorroRepository().getMetas();
  }

  void _recargar() {
    // La carga arranca antes del setState: el callback de setState tiene que
    // ser sincrono (no puede devolver un Future).
    final Future<List<MetaAhorro>> futuro = _cargarMetas();
    if (mounted) {
      setState(() {
        _metasFuture = futuro;
      });
    }
  }

  // Abre el formulario de alta de una meta nueva.
  Future<void> _nuevaMeta() async {
    final bool? creada = await showDialog<bool>(
      context: context,
      builder: (context) => const _DialogoNuevaMeta(),
    );
    if (creada == true) {
      _recargar();
    }
  }

  // Abre el mismo formulario en modo edicion sobre una meta existente.
  Future<void> _editarMeta(MetaAhorro meta) async {
    final bool? guardada = await showDialog<bool>(
      context: context,
      builder: (context) => _DialogoNuevaMeta(meta: meta),
    );
    if (guardada == true) {
      _recargar();
    }
  }

  // Permite depositar ahorro sobre una meta existente.
  Future<void> _depositar(MetaAhorro meta) async {
    final double? monto = await showDialog<double>(
      context: context,
      builder: (context) => _DialogoMovimiento(meta: meta, esRetiro: false),
    );
    if (monto != null && monto > 0) {
      meta.montoAhorrado += monto;
      await MetaAhorroRepository().updateMeta(meta);
      _recargar();
    }
  }

  // Permite retirar ahorro de una meta existente (nunca baja de cero).
  Future<void> _retirar(MetaAhorro meta) async {
    final double? monto = await showDialog<double>(
      context: context,
      builder: (context) => _DialogoMovimiento(meta: meta, esRetiro: true),
    );
    if (monto != null && monto > 0) {
      final double nuevo = meta.montoAhorrado - monto;
      meta.montoAhorrado = nuevo < 0 ? 0 : nuevo;
      await MetaAhorroRepository().updateMeta(meta);
      _recargar();
    }
  }

  // Elimina una meta despues de confirmar.
  Future<void> _eliminar(MetaAhorro meta) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar meta'),
        content: Text('¿Querés eliminar "${meta.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      await MetaAhorroRepository().deleteMeta(meta.id!);
      _recargar();
    }
  }

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
            tooltip: 'Nueva meta',
            onPressed: _nuevaMeta,
          ),
        ],
      ),
      body: FutureBuilder<List<MetaAhorro>>(
        future: _metasFuture,
        builder: (context, snapshot) {
          final List<MetaAhorro> metas = snapshot.data ?? <MetaAhorro>[];
          return _buildContenido(metas);
        },
      ),
    );
  }

  Widget _buildContenido(List<MetaAhorro> metas) {
    final double ahorrado = totalAhorrado(metas);
    double objetivo = 0;
    for (final MetaAhorro meta in metas) {
      objetivo += meta.montoObjetivo;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen general de ahorro (calculado desde SQLite).
          _buildTotalSavingsCard(ahorrado, objetivo),
          const SizedBox(height: 20),

          // Metas activas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Tus Metas Activas',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: _nuevaMeta,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva meta'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (metas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Aún no tenés metas de ahorro. Creá una para empezar.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            ...metas.map((MetaAhorro meta) => _buildGoalCard(meta)),

          const SizedBox(height: 20),

          // Consejos o Tips de Ahorro
          _buildTipCard(),
        ],
      ),
    );
  }

  // Tarjeta de total acumulado (valores reales).
  Widget _buildTotalSavingsCard(double ahorrado, double objetivo) {
    final double avance = porcentaje(ahorrado, objetivo);
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
        children: [
          const Text(
            'Total acumulado en metas',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            formatearMoneda(ahorrado),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Meta global: ${formatearMoneda(objetivo)} '
            '(${(avance * 100).round()}% completado)',
            style: const TextStyle(color: Colors.tealAccent, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Tarjeta para cada objetivo individual.
  Widget _buildGoalCard(MetaAhorro meta) {
    final double progress = progresoMeta(meta);
    final int percentage = (progress * 100).toInt();
    final bool completa = meta.montoAhorrado >= meta.montoObjetivo;

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
                backgroundColor: (completa ? Colors.teal : Colors.indigo).withAlpha(25),
                child: Icon(
                  completa ? Icons.check_circle_outline : Icons.track_changes,
                  color: completa ? Colors.teal : Colors.indigo,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      meta.categoria,
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
                  color: completa ? Colors.teal : Colors.indigo,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Acciones de la meta',
                onSelected: (valor) {
                  if (valor == 'depositar') {
                    _depositar(meta);
                  } else if (valor == 'retirar') {
                    _retirar(meta);
                  } else if (valor == 'editar') {
                    _editarMeta(meta);
                  } else {
                    _eliminar(meta);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'depositar', child: Text('Depositar')),
                  PopupMenuItem(value: 'retirar', child: Text('Retirar')),
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                ],
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
              valueColor: AlwaysStoppedAnimation<Color>(
                completa ? Colors.teal : Colors.indigo,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ahorrado: ${formatearMoneda(meta.montoAhorrado)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                'Objetivo: ${formatearMoneda(meta.montoObjetivo)}',
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
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.teal, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aportando \$15.000 extra por semana podés alcanzar tu meta de vacaciones 1 mes antes.',
              style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

// Formulario de alta y edicion de metas de ahorro.
class _DialogoNuevaMeta extends StatefulWidget {
  // Meta a editar. Null -> modo alta.
  final MetaAhorro? meta;

  const _DialogoNuevaMeta({this.meta});

  @override
  State<_DialogoNuevaMeta> createState() => _DialogoNuevaMetaState();
}

class _DialogoNuevaMetaState extends State<_DialogoNuevaMeta> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _objetivoController = TextEditingController();
  final _fechaController = TextEditingController();
  String _categoria = 'Viajes';

  bool get _esEdicion => widget.meta != null;

  static const List<String> _categorias = <String>[
    'Viajes',
    'Seguridad',
    'Deportes',
    'Hogar',
    'Educacion',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    final MetaAhorro? meta = widget.meta;
    if (meta != null) {
      // Modo edicion: se cargan los datos actuales de la meta.
      _tituloController.text = meta.titulo;
      _objetivoController.text = meta.montoObjetivo.toStringAsFixed(2);
      _fechaController.text = meta.fechaObjetivo;
      _categoria = _categorias.contains(meta.categoria)
          ? meta.categoria
          : 'Otros';
      return;
    }
    // Por defecto: un anio desde hoy.
    final DateTime limite = DateTime.now().add(const Duration(days: 365));
    _fechaController.text =
        '${limite.year}-${limite.month.toString().padLeft(2, '0')}-${limite.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _objetivoController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final DateTime inicial =
        DateTime.tryParse(_fechaController.text) ?? DateTime.now();
    // Si la meta ya tiene una fecha pasada, el picker tiene que poder
    // abrirla: si no, Flutter lanza "initialDate is before firstDate".
    final DateTime hoy = DateTime.now();
    final DateTime primera = inicial.isBefore(hoy) ? inicial : hoy;
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: primera,
      lastDate: DateTime(2100, 12),
    );
    if (fecha != null) {
      _fechaController.text =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final double objetivo =
        double.tryParse(_objetivoController.text.replaceAll(',', '.')) ?? 0;
    // En modo edicion se conservan el id y lo ya ahorrado: solo cambian
    // titulo, categoria, objetivo y fecha.
    final MetaAhorro meta = MetaAhorro(
      _tituloController.text.trim(),
      _categoria,
      objetivo,
      widget.meta?.montoAhorrado ?? 0,
      _fechaController.text,
      widget.meta?.id,
    );
    if (_esEdicion) {
      await MetaAhorroRepository().updateMeta(meta);
    } else {
      await MetaAhorroRepository().addMeta(meta);
    }
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? 'Editar meta' : 'Nueva meta'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Ingresá un título'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categoria,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: _categorias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (valor) =>
                    setState(() => _categoria = valor ?? 'Otros'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _objetivoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto objetivo',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresá el monto objetivo';
                  }
                  final double? monto =
                      double.tryParse(value.replaceAll(',', '.'));
                  if (monto == null || monto <= 0) {
                    return 'Ingresá un monto valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fechaController,
                readOnly: true,
                onTap: _elegirFecha,
                decoration: const InputDecoration(
                  labelText: 'Fecha objetivo',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Elegí una fecha'
                    : null,
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
          child: Text(_esEdicion ? 'Guardar cambios' : 'Crear meta'),
        ),
      ],
    );
  }
}

// Dialogo para depositar o retirar ahorro sobre una meta.
//
// `esRetiro == false` -> deposita; `esRetiro == true` -> retira (validando
// que no se saque mas de lo ahorrado).
class _DialogoMovimiento extends StatefulWidget {
  final MetaAhorro meta;
  final bool esRetiro;

  const _DialogoMovimiento({required this.meta, required this.esRetiro});

  @override
  State<_DialogoMovimiento> createState() => _DialogoMovimientoState();
}

class _DialogoMovimientoState extends State<_DialogoMovimiento> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final double monto =
        double.tryParse(_montoController.text.replaceAll(',', '.')) ?? 0;
    Navigator.of(context).pop(monto);
  }

  @override
  Widget build(BuildContext context) {
    final String accion = widget.esRetiro ? 'Retirar' : 'Depositar';
    return AlertDialog(
      title: Text(
        widget.esRetiro
            ? 'Retirar de "${widget.meta.titulo}"'
            : 'Depositar en "${widget.meta.titulo}"',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ahorrado: ${formatearMoneda(widget.meta.montoAhorrado)} '
                'de ${formatearMoneda(widget.meta.montoObjetivo)}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              // Deja claro que el movimiento se refleja en el saldo del inicio.
              Text(
                widget.esRetiro
                    ? 'Al retirar, el dinero vuelve a tu saldo del inicio.'
                    : 'Al depositar, el dinero sale de tu saldo del inicio.',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: widget.esRetiro
                      ? 'Monto a retirar'
                      : 'Monto a depositar',
                  prefixText: '\$',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresá el monto';
                  }
                  final double? monto =
                      double.tryParse(value.replaceAll(',', '.'));
                  if (monto == null || monto <= 0) {
                    return 'Ingresá un monto valido';
                  }
                  if (widget.esRetiro && monto > widget.meta.montoAhorrado) {
                    return 'No podés retirar más de '
                        '${formatearMoneda(widget.meta.montoAhorrado)}';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardar,
          child: Text(accion),
        ),
      ],
    );
  }
}
