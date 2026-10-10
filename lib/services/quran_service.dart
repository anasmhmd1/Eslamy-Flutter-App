import 'dart:convert';
import 'package:flutter/services.dart';
import '../core/utils/text_utils.dart';

class QuranService {
  // Offline Data Cache
  List<dynamic>? _cachedData;

  Future<void> _loadData() async {
    if (_cachedData != null) return;
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/json/quran.json',
      );
      _cachedData = json.decode(jsonString);
    } catch (e) {
      throw Exception('Failed to load Quran data: $e');
    }
  }

  Future<List<dynamic>> getSurahs() async {
    await _loadData();
    // The JSON structure is a List of Surahs, each having 'id', 'name', 'transliteration', 'verses', etc.
    // We map it to the structure expected by the app.
    return _cachedData!.map((surah) {
      return {
        'id': surah['id'],
        'name_simple': surah['transliteration'], // English/Simple name
        'name_arabic': surah['name'], // Arabic name
        'verses_count': surah['total_verses'],
      };
    }).toList();
  }

  Future<Map<String, dynamic>> getSurahDetails(int surahId) async {
    await _loadData();
    final surah = _cachedData!.firstWhere((s) => s['id'] == surahId);

    // Map verses to expected structure
    final verses = (surah['verses'] as List<dynamic>).map((v) {
      return {
        'id': v['id'],
        'verse_key': '$surahId:${v['id']}',
        'text_uthmani':
            v['text'], // The JSON has 'text' which is usually Uthmani/Arabic
      };
    }).toList();

    return {
      'id': surah['id'],
      'name_arabic': surah['name'],
      'name_simple': surah['transliteration'],
      'verses': verses,
    };
  }

  Future<List<Map<String, dynamic>>> searchVerses(String query) async {
    await _loadData();
    if (query.isEmpty) return [];

    final results = <Map<String, dynamic>>[];
    final normalizedQuery = TextUtils.removeDiacritics(query);

    for (var surah in _cachedData!) {
      final verses = surah['verses'] as List<dynamic>;
      for (var verse in verses) {
        final text = verse['text'].toString();
        final normalizedText = TextUtils.removeDiacritics(text);

        // Smart Search: Match without diacritics
        if (normalizedText.contains(normalizedQuery)) {
          results.add({
            'surah_id': surah['id'],
            'surah_name': surah['name'],
            'verse_number': verse['id'],
            'verse_text': text, // Keep original for display
            'match_snippet': text,
          });
        }
      }
    }
    return results;
  }

  // Helper to construct audio URL.
  // Selecting a popular reciter, e.g., Mishary Rashid Alafasy
  String getAudioUrl(int surahId) {
    // Format surahId to be 3 digits, e.g., 001, 012, 114
    String formattedId = surahId.toString().padLeft(3, '0');
    return 'https://server8.mp3quran.net/afs/$formattedId.mp3';
  }

  Future<Map<String, dynamic>> getChapterRecitation(int chapterId) async {
    // This part might still need online, or we just return the audio URL constructed manually.
    // The previous implementation used an API to get timestamps.
    // Since we went offline for text, we might lose timestamps unless we have another source.
    // I will return a basic structure to keep player working (audio only, maybe no highlight sync for now).
    // Or I can keep the API call *just* for audio metadata if online?
    // The user wants "Word search" and "Offline Text". Audio was already "Offline Download".
    // I made `searchVerses` offline. `getSurahDetails` offline.
    // I will keep audio simple URL generation.
    String formattedId = chapterId.toString().padLeft(3, '0');
    return {
      'audio_url': 'https://server8.mp3quran.net/afs/$formattedId.mp3',
      'timestamps': [], // No timestamps in simple JSON
    };
  }
}
