import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import 'chat_detail_screen.dart';
import 'compass_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'dart:async';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  Position? _currentPosition;
  String? _currentUserAddress;
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _locationError;
  String _searchQuery = '';
  List<User> _users = [];
  TextEditingController _searchController = TextEditingController();
  static const double _maxDistance = 10.0; // Maximum distance in kilometers
  Timer? _locationUpdateTimer;
  Timer? _usersUpdateTimer;
  final _authService = AuthService();
  late final UserService _userService;

  @override
  void initState() {
    super.initState();
    _userService = UserService(_authService);
    _initializeScreen();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationUpdateTimer?.cancel();
    _usersUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await _loadCachedLocation();
    await _getCurrentLocation();
    await _loadUsers();
    _startPeriodicUpdates();
  }

  Future<void> _loadCachedLocation() async {
    try {
      final cachedLocation = await _userService.getCachedLocation();
      if (cachedLocation['latitude'] != null &&
          cachedLocation['longitude'] != null) {
        _currentPosition = Position(
          latitude: cachedLocation['latitude']!,
          longitude: cachedLocation['longitude']!,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        setState(() {});
      }
    } catch (e) {
      print('Error loading cached location: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return Future.error('Location permissions are permanently denied');
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);

      // Update location on server and in cache
      await _userService.updateLocation(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _startPeriodicUpdates() {
    // Update location every 5 minutes
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _getCurrentLocation();
    });

    // Update users list every 30 seconds
    _usersUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadUsers();
    });
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;

    try {
      final users = await _userService.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading users: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isUserNearby(User user) {
    if (_currentPosition == null) return false;
    if (user.latitude == null || user.longitude == null) return false;

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      user.latitude!,
      user.longitude!,
    );

    return distance <= 1000; // 1 kilometer radius
  }

  List<User> _sortUsersByDistance() {
    if (_currentPosition == null) return _users;

    final usersWithLocation = _users
        .where((user) => user.latitude != null && user.longitude != null)
        .toList();

    usersWithLocation.sort((a, b) {
      final distanceA = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        a.latitude!,
        a.longitude!,
      );

      final distanceB = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        b.latitude!,
        b.longitude!,
      );

      return distanceA.compareTo(distanceB);
    });

    return usersWithLocation;
  }

  List<User> _getFilteredUsers() {
    if (_currentPosition == null) return [];

    return _users.where((user) {
      if (user.latitude == null || user.longitude == null) return false;

      // Calculate distance
      final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            user.latitude!,
            user.longitude!,
          ) /
          1000; // Convert to kilometers

      // Filter by distance and search query
      final matchesSearch =
          user.username.toLowerCase().contains(_searchQuery.toLowerCase());
      final isWithinRange = distance <= _maxDistance;

      return matchesSearch && isWithinRange;
    }).toList()
      ..sort((a, b) {
        // Sort by distance
        final distanceA = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          a.latitude!,
          a.longitude!,
        );
        final distanceB = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          b.latitude!,
          b.longitude!,
        );
        return distanceA.compareTo(distanceB);
      });
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
  }

  void _openCompass(User user) {
    if (user.latitude == null || user.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User location is not available'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompassScreen(
          userName: user.username,
          targetLatitude: user.latitude!,
          targetLongitude: user.longitude!,
        ),
      ),
    );
  }

  void _navigateToChat(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          username: user.username,
          userId: user.id.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login terlebih dahulu')),
      );
    }

    final filteredUsers = _getFilteredUsers();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(currentUser.username),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _authService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Location Status Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  _locationError != null ? Colors.red[100] : Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _locationError != null
                      ? Icons.error_outline
                      : Icons.location_on,
                  color: _locationError != null ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _locationError != null ? 'Error Lokasi' : 'Lokasi Anda',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _locationError != null
                              ? Colors.red
                              : Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _locationError ??
                            _currentUserAddress ??
                            'Mendapatkan lokasi...',
                        style: TextStyle(
                          fontSize: 13,
                          color: _locationError != null
                              ? Colors.red[700]
                              : Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_locationError != null)
                  TextButton(
                    onPressed: _getCurrentLocation,
                    child: const Text('COBA LAGI'),
                  ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Cari user...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Radius Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Menampilkan user dalam radius ${_maxDistance.toStringAsFixed(1)} km',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // User List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada user dalam radius ${_maxDistance.toStringAsFixed(1)} km',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _getCurrentLocation,
                        child: ListView.builder(
                          itemCount: filteredUsers.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            if (user.latitude == null ||
                                user.longitude == null ||
                                _currentPosition == null) {
                              return const SizedBox();
                            }

                            final distance = Geolocator.distanceBetween(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                              user.latitude!,
                              user.longitude!,
                            );

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                title: Text(user.username),
                                subtitle: Text(
                                  '${(distance / 1000).toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.explore),
                                      onPressed: () => _openCompass(user),
                                      tooltip: 'Lihat arah',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chat),
                                      onPressed: () => _navigateToChat(user),
                                      tooltip: 'Mulai chat',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
