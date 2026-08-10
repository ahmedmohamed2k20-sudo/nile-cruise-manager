import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/warehouse_provider.dart';
import 'reservation_screen.dart';
import 'warehouse_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nile Cruise Manager'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(child: Text(auth.employeeName ?? '')),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => auth.signOut()),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [ReservationScreen(), WarehouseScreen()],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _showAddItemDialog,
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.blue.shade700,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Reservations'),
          BottomNavigationBarItem(icon: Icon(Icons.warehouse), label: 'Warehouse'),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    final name = TextEditingController();
    final qty = TextEditingController();
    final min = TextEditingController();
    final cat = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Item Name')),
              TextField(controller: qty, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              TextField(controller: min, decoration: const InputDecoration(labelText: 'Min Quantity'), keyboardType: TextInputType.number),
              TextField(controller: cat, decoration: const InputDecoration(labelText: 'Category')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (name.text.isEmpty) return;
              Provider.of<WarehouseProvider>(context, listen: false).addItem({
                'name': name.text,
                'quantity': int.tryParse(qty.text) ?? 0,
                'minQuantity': int.tryParse(min.text) ?? 10,
                'category': cat.text.isNotEmpty ? cat.text : 'General',
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
