import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';

class ForgotPasswordApi {
  static const String _baseUrl =
      'https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net';

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final url = Uri.parse('$_baseUrl/api/authen/forgot-password?email=$email');

    try {
      final ioClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);
      final client = IOClient(ioClient);


      final response = await client
          .post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 15));


      return {
        'statusCode': response.statusCode,
        'body': response.body.isNotEmpty ? jsonDecode(response.body) : {},
      };
    } catch (e) {
      throw Exception('Failed to send reset link: $e');
    } finally {
    }
  }
}