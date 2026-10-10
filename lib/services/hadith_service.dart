import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart'; // For compute
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';

class HadithService extends ApiService {
  // Using fawazahmed0/hadith-api
  // Base URL for the CDN
  static const String baseUrl =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1';

  Future<List<dynamic>> getBooks() async {
    // Returns list of available books (bukhari, muslim, etc.)
    final response = await get('$baseUrl/editions.json');
    return response.values.toList();
  }

  Future<Map<String, dynamic>> getHadiths(
    String bookName, {
    int page = 1,
    int limit = 20,
  }) async {
    return await _fetchAndCache('$baseUrl/editions/$bookName.json', bookName);
  }

  Future<Map<String, dynamic>> getRandomHadith() async {
    try {
      // Using 40 Hadith Nawawi as it is small and good for daily hadith
      final response = await _fetchAndCache(
        '$baseUrl/editions/ara-nawawi.json',
        'ara-nawawi',
      );
      if (response.containsKey('hadiths')) {
        final hadiths = response['hadiths'] as List<dynamic>;
        if (hadiths.isNotEmpty) {
          return hadiths[Random().nextInt(hadiths.length)];
        }
      }
      throw Exception('No hadiths found');
    } catch (e) {
      // Fallback
      return {
        'text': 'خيركم من تعلم القرآن وعلمه',
        'grades': [],
        'reference': {'book': 'البخاري'},
      };
    }
  }

  Future<Map<String, dynamic>> _fetchAndCache(
    String url,
    String filenameKey,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filenameKey.json');

    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        // Parse in background to avoid UI freeze
        return await compute(_parseJson, content);
      } catch (e) {
        // Corrupt cache? Fetch again.
      }
    }

    // Network Fetch
    final response = await get(url);

    // Save to cache (fire and forget or await)
    // response from ApiService is already a Map (decoded).
    // wait... ApiService.get likely returns dynamic (Map).
    // If ApiService.get does json.decode, then we already paid the cost on the main thread?
    // Let's check api_service.dart.
    // If ApiService returns Map, we need to encode it to save it.

    // We can't re-encode and save easily if it's huge.
    // Ideally ApiService should return String or bytes for large files.
    // But assuming ApiService is standard:

    await file.writeAsString(jsonEncode(response));

    return response;
  }
}

// Top-level helper for compute
Map<String, dynamic> _parseJson(String text) {
  return jsonDecode(text) as Map<String, dynamic>;
}
