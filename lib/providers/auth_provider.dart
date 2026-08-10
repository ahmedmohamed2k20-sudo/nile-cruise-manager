import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _employeeName;
  bool _isLoading = false;
  String? _errorMessage;

  final Map<String, String> _credentials = {
    'chahdgamal@nile.com': 'chAhd123@',
  };
  final Map<String, String> _names = {
    'chahdgamal@nile.com': 'Chahd Gamal',
  };

  bool get isAuthenticated => _isAuthenticated;
  String? get employeeName => _employeeName;
  String? get employeeId => 'employee_chahd';
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signIn(String email, String password) async {
    _isLoading = true; _errorMessage = null; notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    
    if (_credentials[email.toLowerCase()] == password) {
      _isAuthenticated = true;
      _employeeName = _names[email.toLowerCase()];
      _isLoading = false; notifyListeners();
      return true;
    }
    _errorMessage = 'Invalid email or password';
    _isLoading = false; notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    _isAuthenticated = false; _employeeName = null; _errorMessage = null; notifyListeners();
  }
}
