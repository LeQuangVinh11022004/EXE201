import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart' as io_client;
import 'package:http/io_client.dart';

class RegisterApi {
  static const String _baseUrl =
      'https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net';

  static Future<IOClient> _getClient() async {
    final httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    return io_client.IOClient(httpClient);
  }

  static Future<Map<String, dynamic>> registerCustomer({
    required String email,
    required String userName,
    required String password,
    required String phoneNumber,
    required String fullName,
    required String dateOfBirth,
    required String sex,
  }) async {
    final url = Uri.parse('$_baseUrl/api/authen/register/customer');
    final body = jsonEncode({
      'email': email,
      'userName': userName,
      'password': password,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'sex': sex,
    });

    final client = await _getClient();
    try {

      final response = await client
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      )
          .timeout(const Duration(seconds: 15));


      return {
        'statusCode': response.statusCode,
        'body': response.body.isNotEmpty && isJson(response.body) ? jsonDecode(response.body) : response.body,
      };
    } catch (e) {
      throw Exception('Failed to register customer: $e');
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> registerExpert({
    required String email,
    required String userName,
    required String password,
    required String phoneNumber,
    required String fullName,
    required String dateOfBirth,
    required String sex,
    required String degree,
    required String workplace,
    required String description,
    required String specialty,
  }) async {
    final url = Uri.parse('$_baseUrl/api/authen/register/expert');
    final body = jsonEncode({
      'email': email,
      'userName': userName,
      'password': password,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'sex': sex,
      'expert': {
        'degree': degree,
        'workplace': workplace,
        'description': description,
        'specialty': specialty,
      },
    });

    final client = await _getClient();
    try {

      final response = await client
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      )
          .timeout(const Duration(seconds: 15));


      return {
        'statusCode': response.statusCode,
        'body': response.body.isNotEmpty && isJson(response.body) ? jsonDecode(response.body) : response.body,
      };
    } catch (e) {
      throw Exception('Failed to register expert: $e');
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> confirmEmail({
    required String email,
  }) async {
    final url = Uri.parse('$_baseUrl/api/authen/confirm-email?email=$email');

    final client = await _getClient();
    try {
      final response = await client
          .get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 15));


      final responseBody = response.body.isNotEmpty && isJson(response.body) ? jsonDecode(response.body) : {};
      return {
        'statusCode': response.statusCode,
        'body': responseBody,
        'success': response.statusCode == 200 || response.statusCode == 201,
        'message': responseBody['message'] ?? 'No message provided (status: ${response.statusCode})',
      };
    } catch (e) {
      throw Exception('Failed to confirm email: $e');
    } finally {
      client.close();
    }
  }

  static bool isJson(String str) {
    try {
      jsonDecode(str);
      return true;
    } catch (e) {
      return false;
    }
  }
}