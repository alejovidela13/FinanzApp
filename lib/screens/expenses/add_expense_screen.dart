import 'package:flutter/material.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedCategory = 'Supermercado';
  bool _isShared = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Supermercado', 'icon': Icons.shopping_bag_outlined, 'color': Colors.orange},
    {'name': 'Servicios', 'icon': Icons.home_outlined, 'color': Colors.blue},
    {'name': 'Transporte', 'icon': Icons.directions_car_outlined, 'color': Colors.teal},
    {'name': 'Salidas', 'icon': Icons.local_dining_outlined, 'color': Colors.purple},
    {'name': 'Otros', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Nuevo Gasto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Monto del gasto', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('\$ ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF4C68FF))),
                      IntrinsicWidth(
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Categoría', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['name'];
                return ChoiceChip(
                  label: Text(cat['name'] as String),
                  avatar: Icon(cat['icon'] as IconData, size: 18, color: isSelected ? Colors.white : cat['color'] as Color),
                  selected: isSelected,
                  selectedColor: const Color(0xFF4C68FF),
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                  onSelected: (val) => setState(() => _selectedCategory = cat['name'] as String),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            const Text('Detalle o comercio', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                hintText: 'Ej. Compra semanal Coto',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                title: const Text('Gasto compartido', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Dividir con miembros del hogar o grupo', style: TextStyle(fontSize: 12)),
                activeColor: const Color(0xFF4C68FF),
                value: _isShared,
                onChanged: (val) => setState(() => _isShared = val),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C68FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gasto guardado con éxito')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Guardar Gasto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}