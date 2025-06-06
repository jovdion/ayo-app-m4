import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class TimeHelper {
  static bool _initialized = false;
  static const String _timezoneOffsetKey = 'timezone_offset';
  static int? _cachedOffset;

  static void initialize() {
    if (!_initialized) {
      tz.initializeTimeZones();
      _initialized = true;
    }
  }

  static Future<void> setTimezoneOffset(int offsetInHours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timezoneOffsetKey, offsetInHours);
    _cachedOffset = offsetInHours;
  }

  static Future<int> getTimezoneOffset() async {
    if (_cachedOffset != null) return _cachedOffset!;

    final prefs = await SharedPreferences.getInstance();
    _cachedOffset = prefs.getInt(_timezoneOffsetKey) ?? 0;
    return _cachedOffset!;
  }

  static Future<DateTime> adjustToUserTimezone(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    final selectedTimezone = prefs.getString('timezone') ?? 'Asia/Jakarta';

    // Convert to local time based on selected timezone
    switch (selectedTimezone) {
      case 'Asia/Jakarta':
        return timestamp.add(const Duration(hours: 7)); // WIB: UTC+7
      case 'Asia/Makassar':
        return timestamp.add(const Duration(hours: 8)); // WITA: UTC+8
      case 'Asia/Jayapura':
        return timestamp.add(const Duration(hours: 9)); // WIT: UTC+9
      case 'Europe/London':
        return timestamp; // GMT: UTC+0
      default:
        return timestamp.add(const Duration(hours: 7)); // Default to WIB
    }
  }

  static String formatMessageTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (messageDate == yesterday) {
      return 'Yesterday ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      return DateFormat('dd/MM/yy HH:mm').format(timestamp);
    }
  }

  static String formatMessageTime(String timestamp, double longitude) {
    initialize();

    final dateTime = DateTime.parse(timestamp);
    final location = _getIndonesianTimezone(longitude);
    final localTime = tz.TZDateTime.from(dateTime, location);
    final now = tz.TZDateTime.now(location);
    final difference = now.difference(localTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(localTime); // Today's time
    } else if (difference.inDays < 7) {
      return DateFormat('E HH:mm').format(localTime); // Weekday and time
    } else {
      return DateFormat('MMM d, HH:mm').format(localTime); // Full date and time
    }
  }

  static tz.Location _getIndonesianTimezone(double longitude) {
    // Indonesia has 3 main time zones based on longitude
    if (longitude < 107.5) {
      return tz.getLocation('Asia/Jakarta'); // WIB (UTC+7)
    } else if (longitude < 120) {
      return tz.getLocation('Asia/Makassar'); // WITA (UTC+8)
    } else {
      return tz.getLocation('Asia/Jayapura'); // WIT (UTC+9)
    }
  }
}
