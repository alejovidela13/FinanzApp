import 'package:flutter/material.dart';

import '../data/grupo_repository.dart';
import '../data/miembro_grupo_repository.dart';
import '../model/model.dart';
import '../util/utils.dart';
import 'grupo_detalle_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  late Future<List<Grupo>> _gruposFuture;
  bool _mostrarTodos = false;

  // Claves de icono disponibles para serializar en la base de datos.
  static const Map<String, IconData> _iconos = <String, IconData>{
    'asado': Icons.outdoor_grill_outlined,
    'viaje': Icons.beach_access_outlined,
    'futbol': Icons.sports_soccer_outlined,
    'otro': Icons.group_outlined,
  };

  @override
  void initState() {
    super.initState();
    _gruposFuture = _cargarGrupos();
  }

  @override
  void didUpdateWidget(covariant GroupsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _gruposFuture = _cargarGrupos();
  }

  Future<List<Grupo>> _cargarGrupos() {
    return GrupoRepository().getGrupos();
  }

  void _recargar() {
    // La carga arranca antes del setState: el callback de setState tiene que
    // ser sincrono (no puede devolver un Future).
    final Future<List<Grupo>> futuro = _cargarGrupos();
    if (mounted) {
      setState(() {
        _gruposFuture = futuro;
      });
    }
  }

  // Abre el formulario de alta de un grupo.
  Future<void> _nuevoGrupo() async {
    final bool? creado = await showDialog<bool>(
      context: context,
      builder: (context) => const _DialogoNuevoGrupo(),
    );
    if (creado == true) {
      _recargar();
    }
  }

  // Elimina un grupo despues de confirmar.
  Future<void> _eliminar(Grupo grupo) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: Text('¿Querés eliminar "${grupo.nombre}"?'),
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
      await GrupoRepository().deleteGrupo(grupo.id!);
      _recargar();
    }
  }

  // Abre la ficha del grupo con sus integrantes y deudas individuales.
  // Al volver se recarga la lista porque el saldo del grupo pudo cambiar.
  Future<void> _verDeudas(Grupo grupo) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GrupoDetalleScreen(grupo: grupo),
      ),
    );
    _recargar();
  }

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
            tooltip: 'Nuevo grupo',
            onPressed: _nuevoGrupo,
          ),
        ],
      ),
      body: FutureBuilder<List<Grupo>>(
        future: _gruposFuture,
        builder: (context, snapshot) {
          final List<Grupo> grupos = snapshot.data ?? <Grupo>[];
          return _buildContenido(grupos);
        },
      ),
    );
  }

  Widget _buildContenido(List<Grupo> grupos) {
    // Saldos calculados desde los grupos guardados en SQLite.
    int teDeben = 0;
    int debes = 0;
    for (final Grupo grupo in grupos) {
      if (grupo.saldo > 0) {
        teDeben += grupo.saldo;
      } else if (grupo.saldo < 0) {
        debes += grupo.saldo.abs();
      }
    }

    final List<Grupo> visibles =
        _mostrarTodos ? grupos : grupos.take(3).toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen de deudas y cobros (valores reales).
          _buildBalanceHeader(teDeben, debes),
          const SizedBox(height: 20),

          // Grupos Activos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grupos Activos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (grupos.length > 3)
                TextButton(
                  onPressed: () => setState(() => _mostrarTodos = !_mostrarTodos),
                  child: Text(_mostrarTodos ? 'Ver menos' : 'Ver todos'),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (grupos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Aún no tenés grupos. Creá uno con el botón de arriba.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            ...visibles.map((Grupo grupo) => _buildGroupCard(grupo)),

          const SizedBox(height: 24),

          // Actividad reciente (informacion real de los grupos).
          const Text(
            'Actividad Reciente',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (grupos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sin actividad para mostrar.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            ...grupos.map(
              (Grupo grupo) => _buildRecentActivityItem(
                user: 'Vos',
                action: grupo.saldo > 0
                    ? 'te deben'
                    : grupo.saldo < 0
                        ? 'debés'
                        : 'saldaste',
                group: grupo.nombre,
                amount: grupo.saldo == 0
                    ? 'Saldado'
                    : '${grupo.saldo > 0 ? '+' : '-'}${formatearMoneda(grupo.saldo.abs().toDouble())}',
              ),
            ),
        ],
      ),
    );
  }

  // Tarjeta de balance general (lo que debés vs lo que te deben).
  Widget _buildBalanceHeader(int teDeben, int debes) {
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
              children: [
                const Text(
                  'Te deben en total',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${formatearMoneda(teDeben.toDouble())}',
                  style: const TextStyle(
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
              children: [
                const Text(
                  'Tenés que pagar',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  '-${formatearMoneda(debes.toDouble())}',
                  style: const TextStyle(
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

  // Tarjeta de grupo individual.
  Widget _buildGroupCard(Grupo grupo) {
    final Color colorEstado = grupo.saldo > 0
        ? Colors.green
        : grupo.saldo < 0
            ? Colors.redAccent
            : Colors.grey;
    final String textoEstado = grupo.saldo > 0
        ? 'Te deben ${formatearMoneda(grupo.saldo.toDouble())}'
        : grupo.saldo < 0
            ? 'Debés ${formatearMoneda(grupo.saldo.abs().toDouble())}'
            : 'Todo saldado';

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
      // Tocar la tarjeta abre la ficha con las deudas individuales.
      child: GestureDetector(
        onTap: () => _verDeudas(grupo),
        child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF1E3C72).withAlpha(20),
            child: Icon(
              _iconos[grupo.icono] ?? Icons.group_outlined,
              color: const Color(0xFF1E3C72),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grupo.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${grupo.integrantes} integrantes',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            textoEstado,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: colorEstado,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Acciones del grupo',
            onSelected: (valor) {
              if (valor == 'ver') {
                _verDeudas(grupo);
              } else if (valor == 'eliminar') {
                _eliminar(grupo);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'ver', child: Text('Ver deudas')),
              const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
            ],
          ),
        ],
        ),
      ),
    );
  }

  // Ítem de actividad reciente generado desde los grupos reales.
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

// Formulario de alta de grupos compartidos.
//
// Se cargan los nombres de los integrantes (todavia sin deuda): cada
// deuda individual se carga despues, desde la ficha del grupo.
class _DialogoNuevoGrupo extends StatefulWidget {
  const _DialogoNuevoGrupo();

  @override
  State<_DialogoNuevoGrupo> createState() => _DialogoNuevoGrupoState();
}

class _DialogoNuevoGrupoState extends State<_DialogoNuevoGrupo> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _integrantesController = TextEditingController();
  String _icono = 'otro';

  static const Map<String, String> _nombresIconos = <String, String>{
    'asado': 'Asado',
    'viaje': 'Viaje',
    'futbol': 'Fútbol',
    'otro': 'Otro',
  };

  @override
  void dispose() {
    _nombreController.dispose();
    _integrantesController.dispose();
    super.dispose();
  }

  // Separa los nombres por comas y/o saltos de linea, descartando vacios.
  List<String> _nombresIntegrantes() {
    return _integrantesController.text
        .split(RegExp(r'[\n,]+'))
        .map((String nombre) => nombre.trim())
        .where((String nombre) => nombre.isNotEmpty)
        .toList();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final List<String> nombres = _nombresIntegrantes();
    // El grupo arranca sin deudas: el saldo total es 0 hasta que se carguen
    // las deudas individuales desde la ficha.
    final Grupo grupo = Grupo(
      _nombreController.text.trim(),
      nombres.length,
      0,
      _icono,
    );
    final int grupoId = await GrupoRepository().addGrupo(grupo);
    for (final String nombre in nombres) {
      await MiembroGrupoRepository().addMiembro(MiembroGrupo(grupoId, nombre, 0));
    }
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo grupo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del grupo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Ingresá un nombre'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _integrantesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Integrantes (separados por coma)',
                  hintText: 'Ej: Ana, Luis, Sofia',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null ||
                        value.split(RegExp(r'[\n,]+')).where((String n) => n.trim().isNotEmpty).isEmpty)
                    ? 'Ingresá al menos un integrante'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _icono,
                decoration: const InputDecoration(
                  labelText: 'Icono',
                  border: OutlineInputBorder(),
                ),
                items: _nombresIconos.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (valor) => setState(() => _icono = valor ?? 'otro'),
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
          child: const Text('Crear grupo'),
        ),
      ],
    );
  }
}
