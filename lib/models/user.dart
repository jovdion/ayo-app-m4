import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final int id;
  final String username;
  final String email;
  final double? latitude;
  final double? longitude;
  final DateTime? lastLocationUpdate;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.latitude,
    this.longitude,
    this.lastLocationUpdate,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    double? lat;
    double? lng;
    DateTime? locationUpdate;

    try {
      // Try to get location from encrypted data first
      if (map['encrypted_location'] != null) {
        // Location will be decrypted on the server side
        lat = map['latitude'];
        lng = map['longitude'];

        if (map['last_location_update'] != null) {
          locationUpdate = DateTime.parse(map['last_location_update']);
        }
      } else {
        // Fallback to direct latitude/longitude
        if (map['latitude'] != null) {
          try {
            lat = double.parse(map['latitude'].toString());
          } catch (e) {
            print('Error parsing latitude: $e');
          }
        }

        if (map['longitude'] != null) {
          try {
            lng = double.parse(map['longitude'].toString());
          } catch (e) {
            print('Error parsing longitude: $e');
          }
        }
      }
    } catch (e) {
      print('Error processing location data: $e');
    }

    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      latitude: lat,
      longitude: lng,
      lastLocationUpdate: locationUpdate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'last_location_update': lastLocationUpdate?.toIso8601String(),
    };
  }

  // Save current user's location to SharedPreferences
  Future<void> saveLocationToPrefs() async {
    if (latitude == null || longitude == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_latitude', latitude!);
    await prefs.setDouble('user_longitude', longitude!);
    await prefs.setString(
        'location_update_time',
        lastLocationUpdate?.toIso8601String() ??
            DateTime.now().toIso8601String());
  }

  // Get current user's location from SharedPreferences
  static Future<Map<String, double?>> getLocationFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'latitude': prefs.getDouble('user_latitude'),
      'longitude': prefs.getDouble('user_longitude'),
    };
  }

  // Calculate distance between two points using Haversine formula
  double calculateDistance(User other) {
    if (latitude == null ||
        longitude == null ||
        other.latitude == null ||
        other.longitude == null) {
      return double.infinity;
    }

    const double earthRadius = 6371; // Earth's radius in kilometers
    var lat1 = latitude! * math.pi / 180;
    var lat2 = other.latitude! * math.pi / 180;
    var dLat = (other.latitude! - latitude!) * math.pi / 180;
    var dLon = (other.longitude! - longitude!) * math.pi / 180;

    var a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    var c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, location: ($latitude, $longitude), lastUpdate: $lastLocationUpdate)';
  }
}
