import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;

class AccountApi {
  static const String _baseUrl =
      'https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net';

  static Future<IOClient> _createClient() async {
    final ioClient = HttpClient();
    return IOClient(ioClient);
  }

  static Future<Map<String, dynamic>> getCurrentUser(String accessToken) async {
    final url = Uri.parse('$_baseUrl/api/account/current');

    try {
      final client = await _createClient();


      final response = await client
          .get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
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
      };
    } catch (e, stackTrace) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  // Include other methods (updateAccount, uploadAvatar) with the same _baseUrl if needed
  static Future<Map<String, dynamic>> updateAccount({
    required String accessToken,
    required String id,
    required String fullName,
    required String dateOfBirth,
    required String sex,
  }) async {
    final url = Uri.parse('$_baseUrl/api/account/$id');

    try {
      final client = await _createClient();

      final response = await client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'fullName': fullName,
          'dateOfBirth': dateOfBirth,
          'sex': sex,
        }),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
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
      };
    } catch (e, stackTrace) {
      throw Exception('Failed to update account: $e');
    }
  }

  static Future<Map<String, dynamic>> uploadAvatar({
    required String accessToken,
    required File file,
  }) async {
    final url = Uri.parse('$_baseUrl/api/account/avatar');

    try {
      final client = await _createClient();

      final request = http.MultipartRequest('PUT', url)
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);


      dynamic responseBody;
      if (response.statusCode == 200) {
        try {
          responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : response.body;
        } catch (e) {
          responseBody = response.body;
        }
      } else {
        throw Exception('Failed to upload avatar: ${response.statusCode} - ${response.body}');
      }

      return {
        'statusCode': response.statusCode,
        'body': responseBody,
      };
    } catch (e, stackTrace) {
      throw Exception('Failed to upload avatar: $e');
    }
  }
}