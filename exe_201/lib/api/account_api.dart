import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;

class AccountApi {
  static const String _baseUrl =
      'https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net';

  static Future<IOClient> _createClient() async {
    final ioClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    return IOClient(ioClient);
  }

  static Future<Map<String, dynamic>> getAppointmentsPagination({
    required String accessToken,
    String? expertId, // Optional but recommended to provide
    int? pageIndex = 1, // Default to 1
    int? pageSize = 10, // Default to 10
    required List<String> appointmentStarusEnum, // Match Swagger parameter
    bool? isDescending = false, // Default to false
  }) async {
    final client = await _createClient();
    try {
      final url = Uri.parse('$_baseUrl/api/appointment/pagination')
          .replace(queryParameters: {
        'pageIndex': pageIndex.toString(), // Provide default
        'pageSize': pageSize.toString(), // Provide default
        if (expertId != null) 'userId': expertId, // Provide if available
        if (appointmentStarusEnum.isNotEmpty) 'appointmentStarusEnum': appointmentStarusEnum.join(','),
        if (isDescending != null) 'isDescending': isDescending.toString(),
      });

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

      if (response.statusCode == 200) {
        if (responseBody is Map && responseBody['items'] != null) {
          return {
            'statusCode': response.statusCode,
            'body': responseBody,
          };
        } else {
          throw Exception('Invalid response format: Expected a Map with "items" key - ${response.body}');
        }
      } else {
        throw Exception(
            'Failed to fetch appointments: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      throw Exception('Failed to fetch appointments: $e');
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> getExpertCalendar({
    required String accessToken,
    required String expertId,
    int? month,
    int? year,
  }) async {
    final url = Uri.parse('$_baseUrl/api/expert/$expertId/calendar')
        .replace(queryParameters: {
      if (month != null) 'month': month.toString(),
      if (year != null) 'year': year.toString(),
    });

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
      throw Exception('Failed to fetch expert calendar: $e');
    }
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

  static Future<Map<String, dynamic>> updateAppointmentStatus({
    required String accessToken,
    required String id,
    required String status, // Cho phép truyền bất kỳ trạng thái hợp lệ
  }) async {
    final client = await _createClient();
    try {
      final url = Uri.parse('$_baseUrl/api/appointment/$id');
      print('Request URL: $url'); // Log URL để debug

      // Kiểm tra xem trạng thái có hợp lệ không
      final validStatuses = ['Canceled', 'Completed', 'Pending', 'Approved'];
      if (!validStatuses.contains(status)) {
        throw Exception('Invalid status value. Must be one of: $validStatuses');
      }

      final response = await client
          .put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(status), // Gửi trạng thái dưới dạng JSON
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

      if (response.statusCode == 200) {
        return {
          'statusCode': response.statusCode,
          'body': responseBody,
        };
      } else {
        throw Exception(
            'Failed to update appointment status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    } finally {
      client.close();
    }
  }

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