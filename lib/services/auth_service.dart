import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../config/api_config.dart';

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;

  Future<String?> getToken() async {
    if (_token != null) return _token;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      return User.fromMap(json.decode(userStr));
    }
    return null;
  }

  // Add method to update current user
  void updateCurrentUser(User user) {
    print('Updating current user: $user');
    _currentUser = user;
  }

  bool isLoggedIn() {
    return _currentUser != null && _token != null;
  }

  Future<void> loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('token');
      final storedUser = prefs.getString('user');

      if (storedToken != null && storedUser != null) {
        _token = storedToken;
        _currentUser = User.fromMap(json.decode(storedUser));
        print('Loaded stored auth - Token: $_token');
        print('Loaded stored auth - User: ${_currentUser?.toString()}');
      }
    } catch (e) {
      print('Error loading stored auth: $e');
      logout();
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _token = data['token'];
        _currentUser = User.fromMap(data['user']);

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(_currentUser!.toMap()));

        return data;
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      print('Error in register: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        _currentUser = User.fromMap(data['user']);

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(_currentUser!.toMap()));

        return data;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      print('Error in login: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('user_latitude');
    await prefs.remove('user_longitude');
    await prefs.remove('location_update_time');
  }

  String _parseErrorMessage(String responseBody) {
    try {
      final data = json.decode(responseBody);
      if (data['message'] != null) {
        return data['message'];
      } else if (data['error'] != null) {
        return data['error'];
      }
    } catch (e) {
      // If response is not JSON, return the raw body
      if (responseBody.contains('<!DOCTYPE html>')) {
        // Extract message from HTML error page
        final match = RegExp(r'<pre>(.*?)</pre>').firstMatch(responseBody);
        if (match != null && match.groupCount >= 1) {
          return match.group(1) ?? responseBody;
        }
      }
    }
    return responseBody;
  }
}
