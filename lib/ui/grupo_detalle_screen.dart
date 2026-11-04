import 'package:flutter/material.dart';

import '../data/gasto_repository.dart';
import '../data/grupo_repository.dart';
import '../data/miembro_grupo_repository.dart';
import '../model/model.dart';
import '../util/utils.dart';

// Ficha de un grupo: sus integrantes y la deuda individual de cada uno.
//
// Desde aca se cargan las deudas ("me debe" / "le debo"), se registran los
// pagos y cobros (que se convierten en gastos, conectados al saldo del
// inicio) y se agregan o quitan integrantes. Cualquier cambio se refleja en
// el saldo total del grupo (la suma de todas las deudas).
class GrupoDetalleScreen extends StatefulWidget {
  final Grupo grupo;

  const GrupoDetalleScreen({super.key, required this.grupo});

  @override
  State<GrupoDetalleScreen> createState() => _GrupoDetalleScreenState();
}

class _GrupoDetalleScreenState extends State<GrupoDetalleScreen> {
  late Future<List<MiembroGrupo>> _miembrosFuture;

  @override
  void initState() {
    super.initState();
    _miembrosFuture = _cargar();
  }

  Future<List<MiembroGrupo>> _cargar() {
    return MiembroGrupoRepository().getMiembros(widget.grupo.id!);
  }

  // Recarga la lista y sincroniza el grupo (saldo total e integrantes)
  // con las deudas individuales recien modificadas.
  Future<void> _trasCambio() async {
    final List<MiembroGrupo> miembros = await _cargar();
    widget.grupo.saldo = totalDeudasGrupo(miembros).round();
    widget.grupo.integrantes = miembros.length;
    await GrupoRepository().updateGrupo(widget.grupo);
    if (mounted) {
      setState(() {
        _miembrosFuture = Future<List<MiembroGrupo>>.value(miembros);
      });
    }
  }

  // Agrega un integrante nuevo (sin deuda cargada todavia).
  Future<void> _agregar() async {
    final MiembroGrupo? creado = await showDialog<MiembroGrupo>(
      context: context,
      builder: (context) => _DialogoMiembro(grupoId: widget.grupo.id!),
    );
    if (creado == null) {
      return;
    }
    await MiembroGrupoRepository().addMiembro(creado);
    await _trasCambio();
  }

  // Edita el nombre o la deuda de un integrante existente.
  Future<void> _editar(MiembroGrupo miembro) async {
    final MiembroGrupo? guardado = await showDialog<MiembroGrupo>(
      context: context,
      builder: (context) => _DialogoMiembro(
        grupoId: widget.grupo.id!,
        miembro: miembro,
      ),
    );
    if (guardado == null) {
      return;
    }
    await MiembroGrupoRepository().updateMiembro(guardado);
    await _trasCambio();
  }

  // Registra un pago (le debo) o un cobro (me debe): mueve la deuda hacia
  // cero y crea el gasto correspondiente para que impacte en el saldo.
  Future<void> _pagarCobrar(MiembroGrupo miembro, {required bool esPago}) async {
    final double? monto = await showDialog<double>(
      context: context,
      builder: (context) =>
          _DialogoMontoMiembro(miembro: miembro, esPago: esPago),
    );
    if (monto == null || monto <= 0 || !mounted) {
      return;
    }

    if (esPago) {
      // Le pago: mi deuda baja. El pago es plata que sale -> gasto positivo.
      miembro.deuda += monto;
      await GastoRepository().addGasto(Gasto(
        'Pago a ${miembro.nombre}',
        monto,
        'General',
        fechaHoy(),
        0,
        0,
        0,
      ));
    } else {
      // Me pagan: mi deuda baja. El cobro es plata que entra -> gasto negativo.
      miembro.deuda -= monto;
      await GastoRepository().addGasto(Gasto(
        'Cobro de ${miembro.nombre}',
        -monto,
        'General',
        fechaHoy(),
        0,
        0,
        0,
      ));
    }

    // Evita residuos de coma flotante (ej. 1000 - 999.999... = 0.000001).
    if (miembro.deuda.abs() < 0.005) {
      miembro.deuda = 0;
    }

    await MiembroGrupoRepository().updateMiembro(miembro);
    await _trasCambio();
  }

  // Elimina un integrante despues de confirmar.
  Future<void> _eliminar(MiembroGrupo miembro) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar integrante'),
        content: Text('¿Querés eliminar "${miembro.nombre}" del grupo?'),
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
      await MiembroGrupoRepository().deleteMiembro(miembro.id!);
      await _trasCambio();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: Text(
          widget.grupo.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<MiembroGrupo>>(
        future: _miembrosFuture,
        builder: (context, snapshot) {
          final List<MiembroGrupo> miembros = snapshot.data ?? <MiembroGrupo>[];
          return _buildContenido(miembros);
        },
      ),
    );
  }

  Widget _buildContenido(List<MiembroGrupo> miembros) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResumen(miembros),
          const SizedBox(height: 20),
          const Text(
            'Integrantes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (miembros.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Aún no tenés integrantes cargados.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            ...miembros.map((MiembroGrupo miembro) => _buildItemMiembro(miembro)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _agregar,
            icon: const Icon(Icons.person_add_alt_outlined),
            label: const Text('Agregar integrante'),
          ),
        ],
      ),
    );
  }

  // Tarjeta de resumen: el saldo total del grupo (suma de las deudas).
  Widget _buildResumen(List<MiembroGrupo> miembros) {
    final double total = totalDeudasGrupo(miembros);
    final Color color = total > 0
        ? Colors.green
        : total < 0
            ? Colors.redAccent
            : Colors.grey;
    final String texto = total > 0
        ? 'Te deben ${formatearMoneda(total)}'
        : total < 0
            ? 'Debés ${formatearMoneda(total.abs())}'
            : 'Todo saldado';

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
                  'Total del grupo',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  texto,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${miembros.length} integrantes',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // Fila de cada integrante con su deuda individual y sus acciones.
  Widget _buildItemMiembro(MiembroGrupo miembro) {
    // Deuda con signo para el usuario: me debe (verde) / le debo (rojo).
    final Color color = miembro.deuda > 0
        ? Colors.green
        : miembro.deuda < 0
            ? Colors.redAccent
            : Colors.grey;
    final String texto = miembro.deuda > 0
        ? 'Me debe ${formatearMoneda(miembro.deuda)}'
        : miembro.deuda < 0
            ? 'Le debés ${formatearMoneda(miembro.deuda.abs())}'
            : 'Al día';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF1E3C72).withAlpha(20),
            child: Text(
              miembro.nombre.isEmpty
                  ? '?'
                  : miembro.nombre.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF1E3C72),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              miembro.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Text(
            texto,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Acciones de ${miembro.nombre}',
            onSelected: (valor) {
              if (valor == 'editar') {
                _editar(miembro);
              } else if (valor == 'pagar') {
                _pagarCobrar(miembro, esPago: true);
              } else if (valor == 'cobrar') {
                _pagarCobrar(miembro, esPago: false);
              } else if (valor == 'eliminar') {
                _eliminar(miembro);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'editar', child: Text('Editar deuda')),
              // Cada accion aparece solo si tiene sentido con la deuda actual.
              if (miembro.deuda < 0)
                const PopupMenuItem(value: 'pagar', child: Text('Pagar')),
              if (miembro.deuda > 0)
                const PopupMenuItem(value: 'cobrar', child: Text('Me pagan')),
              const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
    );
  }
}

// Dialogo para dar de alta o editar un integrante: nombre y deuda inicial
// ("me debe" o "le debo"). Con monto 0 el integrante queda al dia.
class _DialogoMiembro extends StatefulWidget {
  final int grupoId;
  final MiembroGrupo? miembro; // null -> alta, con valor -> edicion

  const _DialogoMiembro({required this.grupoId, this.miembro});

  @override
  State<_DialogoMiembro> createState() => _DialogoMiembroState();
}

class _DialogoMiembroState extends State<_DialogoMiembro> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _montoController = TextEditingController();
  late bool _meDebe;

  bool get _esEdicion => widget.miembro != null;

  @override
  void initState() {
    super.initState();
    final MiembroGrupo? miembro = widget.miembro;
    if (miembro != null) {
      _nombreController.text = miembro.nombre;
      _montoController.text = miembro.deuda.abs().toStringAsFixed(0);
      _meDebe = miembro.deuda >= 0;
    } else {
      _montoController.text = '0';
      _meDebe = true;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final double monto =
        double.tryParse(_montoController.text.replaceAll(',', '.')) ?? 0;
    // La deuda se guarda con signo segun la direccion elegida.
    final double deuda = (_meDebe ? 1 : -1) * monto;
    Navigator.of(context).pop(MiembroGrupo(
      widget.grupoId,
      _nombreController.text.trim(),
      deuda,
      widget.miembro?.id,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? 'Deuda de ${widget.miembro!.nombre}' : 'Integrante nuevo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Ingresá un nombre'
                    : null,
              ),
              const SizedBox(height: 12),
              const Text(
                '¿Quién le debe a quién?',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'meDebe', label: Text('Me debe')),
                  ButtonSegment(value: 'leDebo', label: Text('Le debés')),
                ],
                selected: {_meDebe ? 'meDebe' : 'leDebo'},
                onSelectionChanged: (seleccion) =>
                    setState(() => _meDebe = seleccion.first == 'meDebe'),
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
                  final double? monto =
                      double.tryParse((value ?? '').replaceAll(',', '.'));
                  if (monto == null || monto < 0) {
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
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardar,
          child: Text(_esEdicion ? 'Guardar cambios' : 'Agregar'),
        ),
      ],
    );
  }
}

// Dialogo para pagarle o cobrarle a un integrante.
//
// `esPago == true`  -> le pagas (tu deuda baja; crea un gasto positivo).
// `esPago == false` -> te pagan (tu deuda baja; crea un gasto negativo).
// En ambos casos el monto no puede superar la deuda individual.
class _DialogoMontoMiembro extends StatefulWidget {
  final MiembroGrupo miembro;
  final bool esPago;

  const _DialogoMontoMiembro({required this.miembro, required this.esPago});

  @override
  State<_DialogoMontoMiembro> createState() => _DialogoMontoMiembroState();
}

class _DialogoMontoMiembroState extends State<_DialogoMontoMiembro> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();

  double get _maximo => widget.miembro.deuda.abs();

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
    final MiembroGrupo miembro = widget.miembro;
    return AlertDialog(
      title: Text(
        widget.esPago ? 'Pagarle a "${miembro.nombre}"' : '"${miembro.nombre}" te paga',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.esPago
                    ? 'Le debés ${formatearMoneda(_maximo)}'
                    : 'Te debe ${formatearMoneda(_maximo)}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: widget.esPago ? 'Monto a pagar' : 'Monto que te pagan',
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
                  if (monto > _maximo) {
                    return widget.esPago
                        ? 'No podés pagar más de ${formatearMoneda(_maximo)}'
                        : 'No te pueden pagar más de ${formatearMoneda(_maximo)}';
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
          child: Text(widget.esPago ? 'Pagar' : 'Recibir'),
        ),
      ],
    );
  }
}
