import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';

class DealApi {
  static const String baseUrl =  '${AppConfig.apiBaseUrl}'; // Replace with your actual API base URL

  static Future<List<dynamic>> getDeals() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/service-package/deal'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch deals: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching deals: $e');
    }
  }
}