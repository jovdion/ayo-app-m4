import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/time_helper.dart';
import 'chat_list_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'developers_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  late final UserService _userService;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  int _selectedIndex = 1; // Profile tab
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;
  User? _user;
  String _selectedTimezone = 'Asia/Jakarta';

  @override
  void initState() {
    super.initState();
    _userService = UserService(_authService);
    _loadUserProfile();
    _loadTimezone();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ChatListScreen()),
        (route) => false,
      );
    }
    setState(() => _selectedIndex = index);
  }

  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedUser = await _userService.updateUserProfile(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      setState(() {
        _user = updatedUser;
        _passwordController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    setState(() => _isLoading = true);
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        setState(() {
          _user = currentUser;
          _usernameController.text = currentUser.username;
          _emailController.text = currentUser.email;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTimezone() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTimezone = prefs.getString('timezone') ?? 'Asia/Jakarta';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return const SizedBox();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    if (_isEditing) ...[
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'New Password (optional)',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _handleUpdateProfile,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ] else ...[
                      ListTile(
                        title: const Text('Username'),
                        subtitle: Text(user.username),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Email'),
                        subtitle: Text(user.email),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Timezone Selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedTimezone,
                        decoration: const InputDecoration(
                          labelText: 'Timezone',
                          border: InputBorder.none,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Asia/Jakarta',
                              child: Text('WIB (Jakarta)')),
                          DropdownMenuItem(
                              value: 'Asia/Makassar',
                              child: Text('WITA (Makassar)')),
                          DropdownMenuItem(
                              value: 'Asia/Jayapura',
                              child: Text('WIT (Jayapura)')),
                          DropdownMenuItem(
                              value: 'Europe/London',
                              child: Text('London (GMT)')),
                        ],
                        onChanged: (String? newValue) async {
                          if (newValue != null) {
                            setState(() {
                              _selectedTimezone = newValue;
                            });
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('timezone', newValue);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Developers Section
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.code),
                        title: const Text('Developers'),
                        subtitle: const Text('Meet our development team'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DevelopersScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
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
