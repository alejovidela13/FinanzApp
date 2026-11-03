import 'package:flutter/material.dart';
import '../data/gasto_repository.dart';
import '../model/model.dart';
import '../util/utils.dart';

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _conceptController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _categoria = categoriasGasto.first;

  @override
  void dispose() {
    _conceptController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    // Validacion robusta: el formulario bloquea campos invalidos antes de persistir.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final String concepto = _conceptController.text.trim();
    final String expiration = fechaHoy();

    // Se comparan solo las fechas (sin hora) para que un gasto creado hoy
    // no se muestre como vencido.
    final DateTime hoy = DateTime.now();
    final int diasRestantes = ValidadorFecha.diasEntreFechas(hoy, DateTime.parse(expiration));

    // Alertas: 1 si la notificacion ocurre con el umbral indicado, 0 si no.
    final int fqYear = diasRestantes <= 365 ? 1 : 0;
    final int fqHalfYear = diasRestantes <= 180 ? 1 : 0;
    final int fqMonth = diasRestantes <= 30 ? 1 : 0;

    final Gasto gasto = Gasto(
      concepto,
      amount,
      _categoria,
      expiration,
      fqYear,
      fqHalfYear,
      fqMonth,
    );

    // Persistencia delegada al repositorio (base de datos del usuario activo).
    // Se espera a que termine antes de cerrar el formulario, para que la lista
    // de gastos se recargue con el registro ya guardado.
    try {
      await GastoRepository().addGasto(gasto);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el gasto')),
      );
      return;
    }

    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(gasto);
    messenger.showSnackBar(
      SnackBar(content: Text('Gasto de \$${amount.toStringAsFixed(2)} agregado')),
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
              const Text(
                'Agregar gasto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                validator: (value) => (value == null || value.isEmpty) ? 'Ingresá el monto' : null,
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveExpense,
                child: const Text('Guardar gasto'),
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
