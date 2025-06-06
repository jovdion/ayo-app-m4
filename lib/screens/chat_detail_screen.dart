import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../utils/time_helper.dart';
import '../utils/currency_helper.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ChatDetailScreen extends StatefulWidget {
  final String userId;
  final String username;

  const ChatDetailScreen({
    Key? key,
    required this.userId,
    required this.username,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _authService = AuthService();
  late final UserService _userService;
  User? _recipient;
  List<Message> _messages = [];
  bool _isLoading = true;
  Timer? _messageUpdateTimer;
  CompassEvent? _compassEvent;
  StreamSubscription<CompassEvent>? _compassSubscription;
  Position? _currentPosition;
  double? _heading;
  double? distanceKm;
  bool _hasCompass = false;
  final List<String> currencies = CurrencyHelper.supportedCurrencies;
  final Map<int, String> selectedCurrencyPerMessage = {};

  @override
  void initState() {
    super.initState();
    _userService = UserService(_authService);
    _loadRecipientProfile();
    _loadMessages();
    _initializeCompass();
    _getCurrentLocation();
    _startMessageUpdateTimer();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeCompass() async {
    _hasCompass = await FlutterCompass.events != null;

    if (_hasCompass) {
      _compassSubscription = FlutterCompass.events!.listen((event) {
        if (mounted) {
          setState(() {
            _heading = event.heading;
          });
        }
      });
    }
  }

  Future<void> _loadRecipientProfile() async {
    try {
      final user = await _userService.getUserProfile(int.parse(widget.userId));
      setState(() {
        _recipient = user;
      });
    } catch (e) {
      print('Error loading recipient profile: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      print('Loading messages for user: ${widget.userId}');
      final loadedMessages = await _userService.getMessages(widget.userId);
      print('Messages loaded: ${loadedMessages.length}');
      print(
          'Messages data: ${loadedMessages.map((m) => 'id=${m.id}, senderId=${m.senderId}, receiverId=${m.receiverId}').join('\n')}');

      setState(() {
        _messages = loadedMessages;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _updateDistance();
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _updateDistance() {
    if (_currentPosition != null &&
        _recipient?.latitude != null &&
        _recipient?.longitude != null) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _recipient!.latitude!,
        _recipient!.longitude!,
      );
      setState(() {
        distanceKm = distance / 1000;
      });
    }
  }

  double _calculateBearing() {
    if (_currentPosition == null ||
        _recipient?.latitude == null ||
        _recipient?.longitude == null) {
      return 0;
    }

    final lat1 = _currentPosition!.latitude * math.pi / 180;
    final lon1 = _currentPosition!.longitude * math.pi / 180;
    final lat2 = _recipient!.latitude! * math.pi / 180;
    final lon2 = _recipient!.longitude! * math.pi / 180;

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    var bearing = math.atan2(y, x);
    bearing = bearing * 180 / math.pi;
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  Future<String> formatTimestamp(DateTime timestamp) async {
    final adjustedTime = await TimeHelper.adjustToUserTimezone(timestamp);
    return TimeHelper.formatMessageTimestamp(adjustedTime);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      print('Sending message:');
      print('Receiver ID: ${widget.userId}');
      print('Content: ${text.trim()}');
      print('Current user ID: ${_authService.currentUser?.id}');

      final message =
          await _userService.sendMessage(widget.userId, text.trim());
      print('Message sent successfully:');
      print(
          'Message data: id=${message.id}, senderId=${message.senderId}, receiverId=${message.receiverId}');

      setState(() {
        _messages.add(message);
        _messageController.clear();
      });
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _startMessageUpdateTimer() {
    _messageUpdateTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _loadMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser!;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: _isLoading
            ? const Text('Loading...')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.username),
                ],
              ),
        elevation: 0,
        actions: [
          if (_hasCompass && _heading != null && distanceKm != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Transform.rotate(
                    angle: ((_heading! - _calculateBearing()) * math.pi / 180),
                    child: const Icon(Icons.navigation),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${distanceKm!.toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.only(top: 4),
                    child: _messages.isEmpty
                        ? const Center(
                            child: Text(
                              'No messages yet.\nStart a conversation!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isMe = msg.senderId?.toString() ==
                                  currentUser.id.toString();
                              final hasCurrencyInMessage =
                                  CurrencyHelper.hasCurrency(msg.message);

                              return FutureBuilder<String>(
                                future: formatTimestamp(msg.createdAt),
                                builder: (context, snapshot) {
                                  final timestamp =
                                      snapshot.data ?? 'Loading...';

                                  return Container(
                                    margin: EdgeInsets.only(
                                      left: isMe ? 50 : 8,
                                      right: isMe ? 8 : 50,
                                      bottom: 12,
                                    ),
                                    child: Align(
                                      alignment: isMe
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? Colors.blue[600]
                                              : Colors.grey[200],
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(16),
                                            topRight: const Radius.circular(16),
                                            bottomLeft:
                                                Radius.circular(isMe ? 16 : 0),
                                            bottomRight:
                                                Radius.circular(isMe ? 0 : 16),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isMe
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              msg.message,
                                              style: TextStyle(
                                                color: isMe
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              timestamp,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isMe
                                                    ? Colors.white70
                                                    : Colors.black54,
                                              ),
                                            ),
                                            if (hasCurrencyInMessage) ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: isMe
                                                      ? Colors.white
                                                          .withOpacity(0.1)
                                                      : Colors.grey[300],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .currency_exchange,
                                                          size: 14,
                                                          color: isMe
                                                              ? Colors.white70
                                                              : Colors
                                                                  .grey[600],
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          'Convert to:',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: isMe
                                                                ? Colors.white70
                                                                : Colors
                                                                    .grey[600],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        DropdownButton<String>(
                                                          value:
                                                              selectedCurrencyPerMessage[
                                                                      index] ??
                                                                  currencies
                                                                      .first,
                                                          items: currencies
                                                              .map((currency) {
                                                            return DropdownMenuItem(
                                                              value: currency,
                                                              child: Text(
                                                                currency,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  color: isMe
                                                                      ? Colors
                                                                          .white
                                                                      : Colors.grey[
                                                                          800],
                                                                ),
                                                              ),
                                                            );
                                                          }).toList(),
                                                          onChanged: (value) {
                                                            if (value != null) {
                                                              setState(() {
                                                                selectedCurrencyPerMessage[
                                                                        index] =
                                                                    value;
                                                              });
                                                            }
                                                          },
                                                          dropdownColor: isMe
                                                              ? Colors.blue[700]
                                                              : Colors.white,
                                                          underline:
                                                              const SizedBox(),
                                                          isDense: true,
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    ValueListenableBuilder<
                                                        String>(
                                                      valueListenable:
                                                          ValueNotifier<String>(
                                                              selectedCurrencyPerMessage[
                                                                      index] ??
                                                                  currencies
                                                                      .first),
                                                      builder: (context,
                                                          selectedCurrency, _) {
                                                        final currencies =
                                                            CurrencyHelper
                                                                .extractCurrenciesFromText(
                                                                    msg.message);

                                                        if (currencies
                                                            .isEmpty) {
                                                          return const SizedBox();
                                                        }

                                                        final amount =
                                                            currencies.first[
                                                                    'amount']
                                                                as double;
                                                        final fromCurrency =
                                                            currencies.first[
                                                                    'currency']
                                                                as String;
                                                        final toCurrency =
                                                            selectedCurrency;

                                                        final convertedAmount =
                                                            CurrencyHelper
                                                                .convertCurrency(
                                                          amount,
                                                          fromCurrency,
                                                          toCurrency,
                                                        );

                                                        return Text(
                                                          CurrencyHelper
                                                              .formatCurrency(
                                                                  convertedAmount,
                                                                  toCurrency),
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: isMe
                                                                ? Colors.white
                                                                : Colors
                                                                    .grey[800],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (text) => sendMessage(text),
                          autofocus: false,
                          decoration: InputDecoration(
                            hintText: "Type your message...",
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => sendMessage(_messageController.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
