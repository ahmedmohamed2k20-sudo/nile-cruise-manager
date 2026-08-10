import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/warehouse_provider.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});
  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WarehouseProvider>(context, listen: false).loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WarehouseProvider>(context);
    final filtered = provider.items
        .where((i) => _query.isEmpty || i['name'].toString().toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.blue.shade50,
          child: Column(
            children: [
              TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sort by: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ChoiceChip(
                    label: const Text('Name'),
                    selected: provider.sortBy == 'name',
                    onSelected: (_) => provider.setSortBy('name'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Category'),
                    selected: provider.sortBy == 'category',
                    onSelected: (_) => provider.setSortBy('category'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (provider.lowStockItems.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 8),
                Text('${provider.lowStockItems.length} items low stock',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const Center(child: Text('No items'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final item = filtered[i];
                        final isLow = item['quantity'] <= item['minQuantity'];
                        final isLocked = item['locked'] ?? false;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isLow
                                  ? Colors.orange
                                  : isLocked
                                      ? Colors.grey
                                      : Colors.green,
                              child: Text('${item['quantity']}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                    child: Text(item['name'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.w600))),
                                if (isLocked) const Icon(Icons.lock, size: 16, color: Colors.grey),
                              ],
                            ),
                            subtitle: Text('${item['category'] ?? ''} | Min: ${item['minQuantity']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isLocked) ...[
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.green, size: 20),
                                    onPressed: () => provider.updateQuantity(item['id'], 1),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                                    onPressed: () {
                                      if (item['quantity'] > 0) provider.updateQuantity(item['id'], -1);
                                    },
                                  ),
                                ],
                                IconButton(
                                  icon: Icon(isLocked ? Icons.lock : Icons.lock_open,
                                      color: isLocked ? Colors.grey : Colors.blue, size: 20),
                                  onPressed: () => provider.toggleLock(item['id']),
                                  tooltip: isLocked ? 'Unlock' : 'Lock',
                                ),
                                if (!isLocked) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                    onPressed: () => _editItem(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _confirmDelete(item),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Delete ${item['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Provider.of<WarehouseProvider>(context, listen: false).deleteItem(item['id']);
              Navigator.pop(c);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editItem(Map<String, dynamic> item) {
    final name = TextEditingController(text: item['name']);
    final qty = TextEditingController(text: item['quantity'].toString());
    final min = TextEditingController(text: item['minQuantity'].toString());
    final cat = TextEditingController(text: item['category']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: qty, decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number),
              TextField(controller: min, decoration: const InputDecoration(labelText: 'Min'),
                  keyboardType: TextInputType.number),
              TextField(controller: cat, decoration: const InputDecoration(labelText: 'Category')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Provider.of<WarehouseProvider>(context, listen: false).updateItem(item['id'], {
                'name': name.text,
                'quantity': int.tryParse(qty.text) ?? item['quantity'],
                'minQuantity': int.tryParse(min.text) ?? item['minQuantity'],
                'category': cat.text,
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
