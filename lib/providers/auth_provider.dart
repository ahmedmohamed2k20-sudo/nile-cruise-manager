import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  String? _employeeName;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) _loadEmployeeData(user.uid);
      notifyListeners();
    });
  }

  bool get isAuthenticated => _user != null;
  String? get employeeName => _employeeName;
  String? get employeeId => _user?.uid;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _loadEmployeeData(String uid) async {
    try {
      final doc = await _firestore.collection('employees').doc(uid).get();
      if (doc.exists) _employeeName = doc.data()?['name'];
      notifyListeners();
    } catch (e) {}
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true; _errorMessage = null; notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _isLoading = false; notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message; _isLoading = false; notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async => await _auth.signOut();
}
