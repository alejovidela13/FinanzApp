import 'package:flutter/material.dart';
import '../data/gasto_repository.dart';
import '../model/model.dart';
import '../util/utils.dart';

// Hoja de alta (y edicion) de gastos.
//
// Sin parametro `gasto` da de alta uno nuevo; con `gasto` permite editar uno
// existente. En ambos casos el usuario elige la fecha en que pago el gasto.
class AddExpenseSheet extends StatefulWidget {
  // Gasto a editar. Null -> modo alta.
  final Gasto? gasto;

  const AddExpenseSheet({super.key, this.gasto});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _conceptController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late String _categoria;
  late DateTime _fecha;

  bool get _esEdicion => widget.gasto != null;

  @override
  void initState() {
    super.initState();
    final Gasto? gasto = widget.gasto;
    if (gasto != null) {
      _conceptController.text = gasto.concepto;
      _amountController.text = gasto.monto.toStringAsFixed(2);
      _categoria = categoriasGasto.contains(gasto.categoria)
          ? gasto.categoria
          : categoriasGasto.first;
      _fecha = DateTime.tryParse(gasto.expiration) ?? DateTime.now();
    } else {
      _categoria = categoriasGasto.first;
      _fecha = DateTime.now();
    }
  }

  @override
  void dispose() {
    _conceptController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _aTextoFecha(DateTime fecha) {
    final String mes = fecha.month.toString().padLeft(2, '0');
    final String dia = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }

  // Abre el selector de fecha en que se pago el gasto.
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

  Future<void> _saveExpense() async {
    // Validacion robusta: el formulario bloquea campos invalidos antes de persistir.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final String concepto = _conceptController.text.trim();
    final String expiration = _aTextoFecha(_fecha);

    // Un gasto no vence: los flags de alerta quedan en 0 (solo se conservan
    // en la base por compatibilidad).
    final Gasto gasto = Gasto(
      concepto,
      amount,
      _categoria,
      expiration,
      0,
      0,
      0,
      widget.gasto?.id,
    );

    // Persistencia delegada al repositorio (base de datos del usuario activo).
    // Se espera a que termine antes de cerrar el formulario, para que la lista
    // de gastos se recargue con el registro ya guardado.
    try {
      if (_esEdicion) {
        await GastoRepository().updateGasto(gasto);
      } else {
        await GastoRepository().addGasto(gasto);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_esEdicion
              ? 'No se pudo actualizar el gasto'
              : 'No se pudo guardar el gasto'),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(gasto);
    messenger.showSnackBar(
      SnackBar(
        content: Text(_esEdicion
            ? 'Gasto actualizado'
            : 'Gasto de \$${amount.toStringAsFixed(2)} agregado'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _esEdicion ? 'Editar gasto' : 'Agregar gasto',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conceptController,
                decoration: const InputDecoration(
                  labelText: 'Concepto',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Ingresá un concepto' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresá el monto';
                  }
                  final double? monto = double.tryParse(value.replaceAll(',', '.'));
                  if (monto == null || monto <= 0) {
                    return 'Ingresá un monto mayor a cero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categoria,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: categoriasGasto
                    .map((String c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                    .toList(),
                onChanged: (String? valor) {
                  setState(() => _categoria = valor ?? categoriasGasto.first);
                },
              ),
              const SizedBox(height: 12),
              // Fecha en que se pago el gasto (para agruparlo por mes).
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveExpense,
                child: Text(_esEdicion ? 'Guardar cambios' : 'Guardar gasto'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
