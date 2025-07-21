import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';

import '../config.dart';

class ResetPasswordApi {
  static const String _baseUrl =
      '${AppConfig.apiBaseUrl}';

  static bool isValidBase64(String str) {
    try {
      String cleanStr = str.trim();
      if (cleanStr.startsWith('"') && cleanStr.endsWith('"')) {
        cleanStr = cleanStr.substring(1, cleanStr.length - 1);
      }

      int paddingNeeded = (4 - cleanStr.length % 4) % 4;
      String paddedStr = cleanStr + ('=' * paddingNeeded);

      base64Decode(paddedStr);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    int paddingNeeded = (4 - token.length % 4) % 4;
    String paddedToken = token + ('=' * paddingNeeded);

    if (!isValidBase64(paddedToken)) {
      throw Exception('Invalid token format');
    }

    final encodedToken = Uri.encodeComponent(paddedToken);
    final queryParameters = {
      'email': email,
      'token': encodedToken,
      'newPassword': newPassword,
    };

    final url = Uri.parse('$_baseUrl/api/authen/reset-password')
        .replace(queryParameters: queryParameters);

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
        'body': response.body.isNotEmpty && isJson(response.body)
            ? jsonDecode(response.body)
            : response.body,
      };
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    } finally {
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