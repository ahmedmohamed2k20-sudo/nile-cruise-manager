import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WarehouseProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String _sortBy = 'name';

  List<Map<String, dynamic>> get items {
    List<Map<String, dynamic>> sorted = List.from(_items);
    sorted.sort((a, b) => _sortBy == 'category' ? (a['category'] ?? '').compareTo(b['category'] ?? '') : (a['name'] ?? '').compareTo(b['name'] ?? ''));
    return sorted;
  }
  List<Map<String, dynamic>> get lowStockItems => _items.where((i) => i['quantity'] <= i['minQuantity']).toList();
  bool get isLoading => _isLoading;
  String get sortBy => _sortBy;

  Future<void> loadItems() async {
    _isLoading = true; notifyListeners();
    try {
      final snapshot = await _firestore.collection('warehouse').get();
      _items = snapshot.docs.map((doc) { final data = doc.data(); data['id'] = doc.id; return data; }).toList();
    } catch (e) {}
    _isLoading = false; notifyListeners();
  }

  void setSortBy(String s) { _sortBy = s; notifyListeners(); }

  Future<void> toggleLock(String id) async {
    final i = _items.indexWhere((it) => it['id'] == id);
    if (i != -1) {
      await _firestore.collection('warehouse').doc(id).update({'locked': !(_items[i]['locked'] ?? false)});
      loadItems();
    }
  }

  Future<void> addItem(Map<String, dynamic> item) async {
    item['locked'] = false;
    await _firestore.collection('warehouse').add(item);
    loadItems();
  }

  Future<void> updateQuantity(String id, int change) async {
    final i = _items.indexWhere((it) => it['id'] == id);
    if (i != -1) {
      await _firestore.collection('warehouse').doc(id).update({'quantity': (_items[i]['quantity'] + change).clamp(0, 999999)});
      loadItems();
    }
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    await _firestore.collection('warehouse').doc(id).update(data);
    loadItems();
  }

  Future<void> deleteItem(String id) async {
    await _firestore.collection('warehouse').doc(id).delete();
    loadItems();
  }
}
