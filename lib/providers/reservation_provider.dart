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
    
    for (var r in _allReservations) {
      final start = r['startTime'] as DateTime;
      final end = r['endTime'] as DateTime;
      final prepStart = start.subtract(const Duration(minutes: 30));
      
      // Check if this half-hour SLOT is prep time (the 30 min BEFORE reservation starts)
      // A slot at 9:30 covers 9:30-10:00, so if reservation starts at 10:00, this slot IS prep
      final slotEnd = time.add(const Duration(minutes: 30));
      
      // This slot overlaps with prep time (between prepStart and start)
      if (slotEnd.isAfter(prepStart) && time.isBefore(start)) {
        if (time.isBefore(now)) return Colors.red.withOpacity(0.3);
        return Colors.blue.withOpacity(0.5);
      }
      
      // This slot overlaps with the actual reservation (between start and end)
      if (slotEnd.isAfter(start) && time.isBefore(end)) {
        if (time.isBefore(now)) return Colors.red.withOpacity(0.3);
        return Colors.amber.withOpacity(0.7);
      }
    }
    
    if (time.isBefore(now)) return Colors.red.withOpacity(0.3);
    return Colors.green.withOpacity(0.3);
  }

  Map<String, dynamic>? getReservationAtTime(DateTime time) {
    for (var r in _allReservations) {
      final start = r['startTime'] as DateTime;
      final end = r['endTime'] as DateTime;
      final slotEnd = time.add(const Duration(minutes: 30));
      if (slotEnd.isAfter(start) && time.isBefore(end)) {
        return r;
      }
    }
    return null;
  }

  bool hasConflict(DateTime newStart, DateTime newEnd) {
    for (var r in _allReservations) {
      final rStart = r['startTime'] as DateTime;
      final rEnd = r['endTime'] as DateTime;
      final rPrepStart = rStart.subtract(const Duration(minutes: 30));
      
      // New reservation overlaps with existing reservation
      if (newStart.isBefore(rEnd) && newEnd.isAfter(rStart)) return true;
      // New reservation overlaps with existing prep time
      if (newStart.isBefore(rStart) && newEnd.isAfter(rPrepStart)) return true;
      // Existing reservation's prep time overlaps with new reservation
      if (rStart.isBefore(newEnd) && rEnd.isAfter(newStart.subtract(const Duration(minutes: 30)))) return true;
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
