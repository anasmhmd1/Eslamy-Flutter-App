import 'package:shared_preferences/shared_preferences.dart';

class ReciterService {
  static const String _selectedReciterKey = 'selected_reciter_id';

  static Future<String> getSelectedReciterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedReciterKey) ?? 'mishary';
  }

  static Future<void> setSelectedReciterId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedReciterKey, id);
  }
}
