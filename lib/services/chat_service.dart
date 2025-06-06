import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final AuthService _authService = AuthService();

  Future<List<Message>> getMessages(String userId) async {
    try {
      final token = _authService.token;
      if (token == null) {
        throw Exception('No authentication token');
      }

      print('Getting messages for user: $userId');
      final endpoint = '${ApiConfig.getMessagesEndpoint}/$userId';
      print('Get messages URL: ${ApiConfig.baseUrl}$endpoint');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get messages response status: ${response.statusCode}');
      print('Get messages response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> messagesData = json.decode(response.body);
        print('Parsed messages data: $messagesData');
        return messagesData.map((data) => Message.fromMap(data)).toList();
      } else {
        throw Exception('Failed to get messages: ${response.body}');
      }
    } catch (e) {
      print('Error getting messages: $e');
      rethrow;
    }
  }

  Future<Message> sendMessage(String receiverId, String content) async {
    try {
      final token = _authService.token;
      if (token == null) {
        throw Exception('No authentication token');
      }

      print('Sending message:');
      print('Receiver ID: $receiverId');
      print('Content: $content');
      print('Using endpoint: ${ApiConfig.sendMessageEndpoint}');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sendMessageEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'receiverId': receiverId,
          'content': content,
        }),
      );

      print('Send message response status: ${response.statusCode}');
      print('Send message response body: ${response.body}');

      if (response.statusCode == 201) {
        final messageData = json.decode(response.body);
        print('Parsed message data: $messageData');
        return Message.fromMap(messageData);
      } else {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }
}
