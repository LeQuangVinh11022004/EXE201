import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';

class LoginApi {
  static const String _baseUrl =
      'https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net';

  // Helper method to create a secure HttpClient
  static Future<IOClient> _createClient() async {
    final ioClient = HttpClient();
    return IOClient(ioClient);
  }

  static Future<Map<String, dynamic>> login({
    required String userName,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/api/authen/login');
    final body = jsonEncode({
      'userName': userName,
      'password': password,
    });

    try {
      final client = await _createClient();



      final response = await client
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      )
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out after 30 seconds');
      });


      dynamic responseBody;
      try {
        responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } catch (e) {
        throw Exception('Failed to parse response: ${response.body}');
      }

      return {
        'statusCode': response.statusCode,
        'body': responseBody,
        'accessToken': response.statusCode == 200 ? responseBody['accessToken'] : null,
        'refreshToken': response.statusCode == 200 ? responseBody['refreshToken'] : null,
      };
    } catch (e, stackTrace) {
      throw Exception('Failed to login: $e');
    }
  }
}