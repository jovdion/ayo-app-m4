import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';

class UserService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService;

  UserService(this._authService);

  String _parseErrorMessage(String responseBody) {
    try {
      final data = json.decode(responseBody);
      if (data['message'] != null) {
        return data['message'];
      } else if (data['error'] != null) {
        return data['error'];
      }
    } catch (e) {
      if (responseBody.contains('<!DOCTYPE html>')) {
        final match = RegExp(r'<pre>(.*?)</pre>').firstMatch(responseBody);
        if (match != null && match.groupCount >= 1) {
          return match.group(1) ?? responseBody;
        }
      }
    }
    return responseBody;
  }

  Future<List<User>> getUsers() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.getUsersEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => User.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load users: ${response.body}');
      }
    } catch (e) {
      print('Error getting users: $e');
      rethrow;
    }
  }

  Future<User> getUserProfile(int userId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.getUserProfileEndpoint}/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return User.fromMap(json.decode(response.body));
      } else {
        throw Exception('Failed to load user profile: ${response.body}');
      }
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  Future<User> updateUserProfile({
    required String username,
    required String email,
    String? password,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No token available');

      final Map<String, dynamic> body = {
        'username': username,
        'email': email,
      };
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      final response = await http.put(
        Uri.parse('$baseUrl${ApiConfig.updateProfileEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return User.fromMap(json.decode(response.body));
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No token available');

      print('Updating location for user');
      print('New coordinates: $latitude, $longitude');
      print('Using token: $token');
      print('Using endpoint: $baseUrl${ApiConfig.updateLocationEndpoint}');

      final response = await http.put(
        Uri.parse('$baseUrl${ApiConfig.updateLocationEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      print('Update location response status: ${response.statusCode}');
      print('Update location response body: ${response.body}');

      if (response.statusCode == 200) {
        // Save location to SharedPreferences for quick access
        final user = User(
          id: (await _authService.getCurrentUser())?.id ?? 0,
          username: '', // These fields aren't needed for location caching
          email: '',
          latitude: latitude,
          longitude: longitude,
          lastLocationUpdate: DateTime.now(),
        );
        await user.saveLocationToPrefs();
      } else {
        throw Exception('Failed to update location: ${response.body}');
      }
    } catch (e) {
      print('Error updating location: $e');
      rethrow;
    }
  }

  Future<Map<String, double?>> getCachedLocation() async {
    return User.getLocationFromPrefs();
  }

  Future<List<Message>> getMessages(String userId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No token available');

      print('Loading messages for user: $userId');
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.getMessagesEndpoint}/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Decoded JSON data: $data');

        final messages = data.map((json) {
          print('Processing message data: $json');
          try {
            final message = Message.fromMap(json);
            print('Successfully parsed message: $message');
            return message;
          } catch (e) {
            print('Error parsing message: $e');
            print('Problematic JSON: $json');
            rethrow;
          }
        }).toList();

        print('Successfully parsed all messages: ${messages.length}');
        return messages;
      } else {
        throw Exception('Failed to load messages: ${response.body}');
      }
    } catch (e) {
      print('Error getting messages: $e');
      rethrow;
    }
  }

  Future<Message> sendMessage(String receiverId, String content) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No token available');

      print('Sending message:');
      print('Receiver ID: $receiverId');
      print('Message: $content');
      print('Current user ID: ${(await _authService.getCurrentUser())?.id}');

      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.sendMessageEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'receiverId': receiverId,
          'message': content,
        }),
      );

      if (response.statusCode == 201) {
        return Message.fromMap(json.decode(response.body));
      } else {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }
}
