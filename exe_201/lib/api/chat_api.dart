import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';

import '../config.dart';

class ChatApi {
  static const String _baseUrl =
      '${AppConfig.apiBaseUrl}';

  static Future<IOClient> _getClient() async {
    final httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    return IOClient(httpClient);
  }

  static Future<Map<String, dynamic>> fetchChatHub(String userId) async {
    final url = Uri.parse('$_baseUrl/api/chat/hubs/user/$userId');

    try {
      final client = await _getClient();


      final response = await client
          .get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 15));


      final responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return {
        'statusCode': response.statusCode,
        'body': responseBody,
      };
    } catch (e) {
      throw Exception('Failed to fetch chat hub: $e');
    } finally {
    }
  }

  static Future<Map<String, dynamic>> fetchChatHubById(String chatHubId) async {
    final url = Uri.parse('$_baseUrl/api/chat/hub/$chatHubId');

    try {
      final client = await _getClient();


      final response = await client
          .get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 15));


      final responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return {
        'statusCode': response.statusCode,
        'body': responseBody,
      };
    } catch (e) {
      throw Exception('Failed to fetch chat hub by id: $e');
    } finally {
    }
  }

  static Future<Map<String, dynamic>> fetchChatHubForDoctor(String doctorId) async {
    final url = Uri.parse('$_baseUrl/api/chat/hubs/user/$doctorId');

    try {
      final client = await _getClient();
      final response = await client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      final responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return {
        'statusCode': response.statusCode,
        'body': responseBody,
      };
    } catch (e) {
      throw Exception('Failed to fetch chat hub for doctor: $e');
    }
  }
}