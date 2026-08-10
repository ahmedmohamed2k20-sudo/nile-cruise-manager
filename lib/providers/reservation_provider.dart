import 'package:flutter/material.dart';

class ReservationProvider with ChangeNotifier {
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> get reservations => _reservations;
  bool get isLoading => _isLoading;

  Future<void> loadReservationsForDate(DateTime date) async {
    _isLoading = true; notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    // Only show reservations for THIS specific date
    _reservations = _allReservations.where((r) {
      final start = r['startTime'] as DateTime;
      return start.year == date.year && start.month == date.month && start.day == date.day;
    }).toList();
    _isLoading = false; notifyListeners();
  }

  // Store all reservations here
  static final List<Map<String, dynamic>> _allReservations = [];

  Color getTimeSlotColor(DateTime time) {
    final now = DateTime.now();
    if (time.isBefore(now)) return Colors.red.withOpacity(0.3);
    final hasReservation = _reservations.any((r) => time.isAfter(r['startTime']) && time.isBefore(r['endTime']));
    if (hasReservation) return Colors.amber.withOpacity(0.7);
    final isPrepTime = _reservations.any((r) => time.isAfter(r['startTime'].subtract(const Duration(minutes: 30))) && time.isBefore(r['startTime']));
    if (isPrepTime) return Colors.blue.withOpacity(0.5);
    return Colors.green.withOpacity(0.3);
  }

  Map<String, dynamic>? getReservationAtTime(DateTime time) {
    for (var r in _reservations) {
      if (time.isAfter(r['startTime']) && time.isBefore(r['endTime'])) return r;
    }
    return null;
  }

  Future<void> addReservation(Map<String, dynamic> data) async {
    data['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    data['createdAt'] = DateTime.now();
    _allReservations.add(data);
    // Reload current date
    if (_reservations.isNotEmpty) {
      loadReservationsForDate(_reservations.first['startTime']);
    }
    notifyListeners();
  }

  Future<void> updateReservation(String id, Map<String, dynamic> data) async {
    final i = _allReservations.indexWhere((r) => r['id'] == id);
    if (i != -1) { _allReservations[i] = {..._allReservations[i], ...data}; notifyListeners(); }
  }

  Future<void> deleteReservation(String id) async {
    _allReservations.removeWhere((r) => r['id'] == id);
    _reservations.removeWhere((r) => r['id'] == id);
    notifyListeners();
  }
}
