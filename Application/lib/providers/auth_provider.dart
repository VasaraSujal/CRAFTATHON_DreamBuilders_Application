import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../data/mock_data.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _user != null && _user!['token'] != null;
  bool get isLoading => _isLoading;
  String get role => _user?['role'] ?? 'Monitor';
  String get name => _user?['name'] ?? '';
  String get email => _user?['email'] ?? '';

  AuthProvider() {
    _loadStoredUser();
  }

  Future<void> _loadStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKeyUser);
      if (raw != null) {
        _user = jsonDecode(raw) as Map<String, dynamic>;
        ApiService.setToken(_user!['token'] as String?);
      }
    } catch (_) {
      // ignore
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    Map<String, dynamic> data;
    try {
      data = await ApiService.loginUser(email, password);
    } catch (_) {
      // Fallback to mock users
      final match = MockUsers.users.firstWhere(
        (u) => u['email'] == email && u['password'] == password,
        orElse: () => {},
      );
      if (match.isEmpty) {
        throw Exception('Invalid email or password');
      }
      data = {
        '_id': match['id'],
        'name': match['name'],
        'email': match['email'],
        'role': match['role'],
        'token': 'mock-token-${match['id']}',
      };
    }

    _user = data;
    ApiService.setToken(data['token'] as String?);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKeyUser, jsonEncode(data));

    notifyListeners();
  }

  Future<void> register(Map<String, dynamic> payload) async {
    final data = await ApiService.registerUser(payload);
    _user = data;
    ApiService.setToken(data['token'] as String?);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKeyUser, jsonEncode(data));

    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    ApiService.setToken(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKeyUser);

    notifyListeners();
  }
}
