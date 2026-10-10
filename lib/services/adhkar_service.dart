import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AdhkarService {
  static const String _morningProgressKey = 'adhkar_morning_progress';
  static const String _eveningProgressKey = 'adhkar_evening_progress';
  static const String _lastDateKey = 'adhkar_last_date';

  /// Get the current date as a string (YYYY-MM-DD)
  static String _getTodayString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Save Adhkar progress
  static Future<void> saveProgress({
    required bool isMorning,
    required List<int> progress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isMorning ? _morningProgressKey : _eveningProgressKey;

    // Save progress as comma-separated string
    await prefs.setString(key, progress.join(','));

    // Save today's date
    await prefs.setString(_lastDateKey, _getTodayString());
  }

  /// Load Adhkar progress
  /// Returns null if no saved progress or if it's a new day
  static Future<List<int>?> loadProgress({required bool isMorning}) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if the saved date is today
    final savedDate = prefs.getString(_lastDateKey);
    final today = _getTodayString();

    if (savedDate != today) {
      // It's a new day, reset progress
      await prefs.remove(_morningProgressKey);
      await prefs.remove(_eveningProgressKey);
      await prefs.setString(_lastDateKey, today);
      return null;
    }

    // Load progress
    final key = isMorning ? _morningProgressKey : _eveningProgressKey;
    final progressString = prefs.getString(key);

    if (progressString == null || progressString.isEmpty) {
      return null;
    }

    try {
      return progressString.split(',').map((s) => int.parse(s)).toList();
    } catch (e) {
      return null;
    }
  }
}
