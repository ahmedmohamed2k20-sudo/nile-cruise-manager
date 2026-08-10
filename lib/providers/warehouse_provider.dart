import 'package:flutter/material.dart';

class WarehouseProvider with ChangeNotifier {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String _sortBy = 'name'; // 'name' or 'category'
  
  List<Map<String, dynamic>> get items {
    List<Map<String, dynamic>> sorted = List.from(_items);
    if (_sortBy == 'category') {
      sorted.sort((a, b) => (a['category'] ?? '').compareTo(b['category'] ?? ''));
    } else {
      sorted.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    }
    return sorted;
  }
  
  List<Map<String, dynamic>> get lowStockItems => _items.where((i) => i['quantity'] <= i['minQuantity']).toList();
  bool get isLoading => _isLoading;
  String get sortBy => _sortBy;

  Future<void> loadItems() async {
    _isLoading = true; notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    if (_items.isEmpty) {
      _items = [
        {'id': '1', 'name': 'Water Bottles', 'quantity': 150, 'minQuantity': 50, 'category': 'Drinks', 'locked': false},
        {'id': '2', 'name': 'Soft Drinks', 'quantity': 80, 'minQuantity': 30, 'category': 'Drinks', 'locked': false},
        {'id': '3', 'name': 'Juice Boxes', 'quantity': 45, 'minQuantity': 50, 'category': 'Drinks', 'locked': false},
        {'id': '4', 'name': 'Snacks', 'quantity': 25, 'minQuantity': 40, 'category': 'Food', 'locked': false},
        {'id': '5', 'name': 'Sandwiches', 'quantity': 60, 'minQuantity': 30, 'category': 'Food', 'locked': false},
        {'id': '6', 'name': 'Cups', 'quantity': 200, 'minQuantity': 100, 'category': 'Utensils', 'locked': true},
        {'id': '7', 'name': 'Napkins', 'quantity': 300, 'minQuantity': 150, 'category': 'Utensils', 'locked': true},
        {'id': '8', 'name': 'Balloons', 'quantity': 15, 'minQuantity': 30, 'category': 'Decoration', 'locked': false},
        {'id': '9', 'name': 'Flowers', 'quantity': 10, 'minQuantity': 20, 'category': 'Decoration', 'locked': false},
      ];
    }
    _isLoading = false; notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void toggleLock(String id) {
    final i = _items.indexWhere((it) => it['id'] == id);
    if (i != -1) {
      _items[i]['locked'] = !(_items[i]['locked'] ?? false);
      notifyListeners();
    }
  }

  Future<void> addItem(Map<String, dynamic> item) async {
    item['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    item['locked'] = false;
    _items.add(item); notifyListeners();
  }

  Future<void> updateQuantity(String id, int change) async {
    final i = _items.indexWhere((it) => it['id'] == id);
    if (i != -1) { _items[i]['quantity'] = (_items[i]['quantity'] + change).clamp(0, 999999); notifyListeners(); }
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    final i = _items.indexWhere((it) => it['id'] == id);
    if (i != -1) { _items[i] = {..._items[i], ...data}; notifyListeners(); }
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((it) => it['id'] == id); notifyListeners();
  }
}
