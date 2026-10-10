import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  Future<dynamic> get(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw HttpException('Failed to load data: ${response.statusCode}');
      }
    } on SocketException {
      throw HttpException('No Internet connection');
    } on TimeoutException {
      throw HttpException('Connection timed out');
    } catch (e) {
      throw HttpException('Network Error: $e');
    }
  }
}
