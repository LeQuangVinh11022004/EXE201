import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

class LogoutApi {
  static const storage = FlutterSecureStorage();
  static const String _baseUrl =
      'https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net';

  static Future<Map<String, dynamic>> logout() async {
    final url = Uri.parse('$_baseUrl/api/authen/logout');

    try {
      final accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        throw Exception('No access token found. Please log in again.');
      }

      final ioClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);
      final client = IOClient(ioClient);


      final response = await client
          .post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 15));


      final contentType = response.headers['content-type']?.toLowerCase();
      dynamic responseBody;

      if (contentType != null && contentType.contains('application/json')) {
        responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      } else {
        responseBody = response.body.isNotEmpty ? response.body : '';
      }

      if (response.statusCode == 200) {
        await storage.delete(key: 'access_token');
        await storage.delete(key: 'user_id');
        await storage.delete(key: 'refresh_token'); // Clear refresh token if exists
      }

      return {
        'statusCode': response.statusCode,
        'body': responseBody,
      };
    } on ClientException catch (e) {
      throw Exception('Connection error: $e (URI: ${url})');
    } on SocketException catch (e) {
      throw Exception('Failed to connect to the server: $e');
    } catch (e) {
      throw Exception('Failed to logout: $e');
    } finally {
    }
  }
}