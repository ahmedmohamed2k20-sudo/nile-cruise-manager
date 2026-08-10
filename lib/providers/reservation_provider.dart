import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _reservations = [];
  DateTime _currentDate = DateTime.now();
  bool _isLoading = false;

  List<Map<String, dynamic>> get reservations => _reservations;
  bool get isLoading => _isLoading;

  Future<void> loadReservationsForDate(DateTime date) async {
    _currentDate = date;
    _isLoading = true; notifyListeners();
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final snapshot = await _firestore.collection('reservations')
          .where('startTime', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('startTime', isLessThan: endOfDay.toIso8601String()).get();
      _reservations = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['startTime'] = DateTime.parse(data['startTime']);
        data['endTime'] = DateTime.parse(data['endTime']);
        return data;
      }).toList();
    } catch (e) {}
    _isLoading = false; notifyListeners();
  }

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
    for (var r in _reservations) { if (time.isAfter(r['startTime']) && time.isBefore(r['endTime'])) return r; }
    return null;
  }

  bool hasConflict(DateTime start, DateTime end) {
    for (var r in _reservations) {
      if (start.isBefore(r['endTime']) && end.isAfter(r['startTime'])) return true;
      if (start.isAfter(r['startTime'].subtract(const Duration(minutes: 30))) && start.isBefore(r['startTime'])) return true;
    }
    return false;
  }

  Future<void> addReservation(Map<String, dynamic> data) async {
    final start = data['startTime'] as DateTime;
    final end = data['endTime'] as DateTime;
    if (hasConflict(start, end)) return;
    await _firestore.collection('reservations').add({
      'customerName': data['customerName'], 'employeeName': data['employeeName'],
      'startTime': start.toIso8601String(), 'endTime': end.toIso8601String(),
      'hasDrinks': data['hasDrinks'] ?? false, 'drinksDetails': data['drinksDetails'] ?? '',
      'hasFood': data['hasFood'] ?? false, 'foodDetails': data['foodDetails'] ?? '',
      'hasSpecialDecorations': data['hasSpecialDecorations'] ?? false, 'decoDetails': data['decoDetails'] ?? '',
      'hasBirthdayCake': data['hasBirthdayCake'] ?? false, 'cakeDetails': data['cakeDetails'] ?? '',
      'specialNotes': data['specialNotes'] ?? '', 'createdAt': DateTime.now().toIso8601String(),
    });
    loadReservationsForDate(_currentDate);
  }

  Future<void> deleteReservation(String id) async {
    await _firestore.collection('reservations').doc(id).delete();
    loadReservationsForDate(_currentDate);
  }
}
