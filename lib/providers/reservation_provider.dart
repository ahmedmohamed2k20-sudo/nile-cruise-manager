import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _allReservations = [];
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
      _allReservations = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['startTime'] = DateTime.parse(data['startTime']);
        data['endTime'] = DateTime.parse(data['endTime']);
        return data;
      }).toList();
      _reservations = List.from(_allReservations);
    } catch (e) {
      _allReservations = [];
      _reservations = [];
    }
    _isLoading = false; notifyListeners();
  }

  Color getTimeSlotColor(DateTime time) {
    final now = DateTime.now();
    
    // Check if this exact time slot is within ANY reservation
    for (var r in _allReservations) {
      final start = r['startTime'] as DateTime;
      final end = r['endTime'] as DateTime;
      
      // This exact half-hour slot is inside a reservation
      if (time.isAfter(start.subtract(const Duration(seconds: 1))) && time.isBefore(end)) {
        if (time.isBefore(now)) return Colors.red.withOpacity(0.3);
        return Colors.amber.withOpacity(0.7);
      }
      
      // This slot is within 30 min before a reservation (prep time)
      final prepStart = start.subtract(const Duration(minutes: 30));
      if (time.isAfter(prepStart.subtract(const Duration(seconds: 1))) && time.isBefore(start)) {
        if (time.isBefore(now)) return Colors.red.withOpacity(0.3);
        return Colors.blue.withOpacity(0.5);
      }
    }
    
    if (time.isBefore(now)) return Colors.red.withOpacity(0.3);
    return Colors.green.withOpacity(0.3);
  }

  Map<String, dynamic>? getReservationAtTime(DateTime time) {
    for (var r in _allReservations) {
      final start = r['startTime'] as DateTime;
      final end = r['endTime'] as DateTime;
      if (time.isAfter(start.subtract(const Duration(seconds: 1))) && time.isBefore(end)) {
        return r;
      }
    }
    return null;
  }

  bool hasConflict(DateTime start, DateTime end) {
    for (var r in _allReservations) {
      final rStart = r['startTime'] as DateTime;
      final rEnd = r['endTime'] as DateTime;
      final prepStart = rStart.subtract(const Duration(minutes: 30));
      
      // New reservation overlaps with existing reservation OR its prep time
      if (start.isBefore(rEnd) && end.isAfter(prepStart)) return true;
    }
    return false;
  }

  Future<void> addReservation(Map<String, dynamic> data) async {
    final start = data['startTime'] as DateTime;
    final end = data['endTime'] as DateTime;
    
    if (hasConflict(start, end)) return;
    
    await _firestore.collection('reservations').add({
      'customerName': data['customerName'],
      'employeeName': data['employeeName'],
      'employeeEmail': data['employeeEmail'],
      'startTime': start.toIso8601String(),
      'endTime': end.toIso8601String(),
      'hasDrinks': data['hasDrinks'] ?? false,
      'drinksDetails': data['drinksDetails'] ?? '',
      'hasFood': data['hasFood'] ?? false,
      'foodDetails': data['foodDetails'] ?? '',
      'hasSpecialDecorations': data['hasSpecialDecorations'] ?? false,
      'decoDetails': data['decoDetails'] ?? '',
      'hasBirthdayCake': data['hasBirthdayCake'] ?? false,
      'cakeDetails': data['cakeDetails'] ?? '',
      'specialNotes': data['specialNotes'] ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    });
    await loadReservationsForDate(_currentDate);
  }

  Future<void> deleteReservation(String id) async {
    await _firestore.collection('reservations').doc(id).delete();
    await loadReservationsForDate(_currentDate);
  }
}
