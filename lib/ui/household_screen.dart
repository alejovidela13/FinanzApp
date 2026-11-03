import 'package:flutter/material.dart';

import '../model/model.dart';
import '../data/servicio_hogar_repository.dart';
import '../util/utils.dart';

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key});

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  late Future<List<ServicioHogar>> _serviciosFuture;

  @override
  void initState() {
    super.initState();
    _serviciosFuture = _cargarServicios();
  }

  @override
  void didUpdateWidget(covariant HouseholdScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _serviciosFuture = _cargarServicios();
  }

  Future<List<ServicioHogar>> _cargarServicios() {
    return ServicioHogarRepository().getServicios();
  }

  void _recargar() {
    // La carga arranca antes del setState: el callback de setState tiene que
    // ser sincrono (no puede devolver un Future).
    final Future<List<ServicioHogar>> futuro = _cargarServicios();
    if (mounted) {
      setState(() {
        _serviciosFuture = futuro;
      });
    }
  }

  // Abre el formulario de alta de un servicio del hogar.
  Future<void> _nuevoServicio() async {
    final bool? creado = await showDialog<bool>(
      context: context,
      builder: (context) => const _DialogoNuevoServicio(),
    );
    if (creado == true) {
      _recargar();
    }
  }

  // Marca o desmarca un servicio como pagado (se persiste en SQLite).
  Future<void> _alternarPagado(ServicioHogar servicio) async {
    servicio.pagado = servicio.pagado == 1 ? 0 : 1;
    await ServicioHogarRepository().updateServicio(servicio);
    _recargar();
  }

  // Elimina un servicio despues de confirmar.
  Future<void> _eliminar(ServicioHogar servicio) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar servicio'),
        content: Text('¿Querés eliminar "${servicio.titulo}"?'),
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
      await ServicioHogarRepository().deleteServicio(servicio.id!);
      _recargar();
    }
  }

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
            tooltip: 'Nuevo servicio',
            onPressed: _nuevoServicio,
          ),
        ],
      ),
      body: FutureBuilder<List<ServicioHogar>>(
        future: _serviciosFuture,
        builder: (context, snapshot) {
          final List<ServicioHogar> servicios =
              snapshot.data ?? <ServicioHogar>[];
          return _buildContenido(servicios);
        },
      ),
    );
  }

  Widget _buildContenido(List<ServicioHogar> servicios) {
    double total = 0;
    double pagado = 0;
    double pendiente = 0;
    for (final ServicioHogar servicio in servicios) {
      total += servicio.monto;
      if (servicio.pagado == 1) {
        pagado += servicio.monto;
      } else {
        pendiente += servicio.monto;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen calculado desde los servicios guardados en SQLite.
          _buildBalanceSummaryCard(total, pagado, pendiente, servicios.length),
          const SizedBox(height: 20),

          // Servicios y gastos fijos (datos reales)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Servicios y Gastos Fijos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _nuevoServicio,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (servicios.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Aún no hay servicios cargados. Agregá uno con el botón de arriba.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            ...servicios.map(
              (ServicioHogar servicio) => _buildServiceItem(servicio),
            ),
        ],
      ),
    );
  }

  // Tarjeta de resumen con totales reales.
  Widget _buildBalanceSummaryCard(
    double total,
    double pagado,
    double pendiente,
    int cantidad,
  ) {
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
            'Total Servicios y Hogar',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            formatearMoneda(total),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniIndicator('Pagado', formatearMoneda(pagado), Colors.green),
              _buildMiniIndicator(
                  'Pendiente', formatearMoneda(pendiente), Colors.orange),
              _buildMiniIndicator('Servicios', '$cantidad', Colors.blue),
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

  // Ítem de servicio: al tocar el icono se marca/desmarca como pagado.
  Widget _buildServiceItem(ServicioHogar servicio) {
    final bool pagado = servicio.pagado == 1;

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
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              pagado ? Icons.check_circle : Icons.schedule,
              color: pagado ? Colors.green : Colors.orange,
              size: 24,
            ),
            tooltip: pagado ? 'Marcar como pendiente' : 'Marcar como pagado',
            onPressed: () => _alternarPagado(servicio),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servicio.titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  servicio.detalle.isEmpty
                      ? (pagado ? 'Pagado' : 'Pendiente')
                      : servicio.detalle,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            formatearMoneda(servicio.monto),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          PopupMenuButton<String>(
            tooltip: 'Acciones del servicio',
            onSelected: (valor) {
              if (valor == 'eliminar') {
                _eliminar(servicio);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
    );
  }
}

// Formulario de alta de servicios y gastos fijos del hogar.
class _DialogoNuevoServicio extends StatefulWidget {
  const _DialogoNuevoServicio();

  @override
  State<_DialogoNuevoServicio> createState() => _DialogoNuevoServicioState();
}

class _DialogoNuevoServicioState extends State<_DialogoNuevoServicio> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _detalleController = TextEditingController();
  final _montoController = TextEditingController();

  @override
  void dispose() {
    _tituloController.dispose();
    _detalleController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final double monto =
        double.tryParse(_montoController.text.replaceAll(',', '.')) ?? 0;
    final ServicioHogar servicio = ServicioHogar(
      _tituloController.text.trim(),
      _detalleController.text.trim(),
      monto,
      0,
    );
    await ServicioHogarRepository().addServicio(servicio);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo servicio'),
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
              TextFormField(
                controller: _detalleController,
                decoration: const InputDecoration(
                  labelText: 'Detalle (opcional)',
                  border: OutlineInputBorder(),
                ),
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
                    return 'Ingresá un monto valido';
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
