class Message {
  final String id;
  final String? senderId;
  final String receiverId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    this.senderId,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    print('Creating Message from map: $map');
    try {
      // Handle both camelCase and snake_case field names
      final message = Message(
        id: map['id']?.toString() ?? '',
        senderId: map['sender_id']?.toString() ?? map['senderId']?.toString(),
        receiverId: map['receiver_id']?.toString() ??
            map['receiverId']?.toString() ??
            '',
        message: map['message']?.toString() ?? map['content']?.toString() ?? '',
        isRead: map['is_read'] ?? map['isRead'] ?? false,
        createdAt: _parseDateTime(map['created_at'] ?? map['createdAt']),
      );
      print('Successfully created Message: $message');
      return message;
    } catch (e) {
      print('Error creating Message from map: $e');
      print('Problematic map: $map');
      rethrow;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing datetime: $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, receiverId: $receiverId, message: $message, isRead: $isRead, createdAt: $createdAt)';
  }
}
