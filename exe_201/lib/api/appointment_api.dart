import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/io_client.dart';

import '../config.dart';

class AppointmentApi {
  static const String _baseUrl =
      '${AppConfig.apiBaseUrl}';

  static Future<IOClient> _getClient() async {
    final httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    return IOClient(httpClient);
  }

  static Future<List<Map<String, dynamic>>> fetchTimeSlots() async {
    final client = await _getClient();
    try {
      final response = await client
          .get(
        Uri.parse('$_baseUrl/api/helpper/timeslot'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 15));


      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load time slots: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching time slots: $e');
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> createAppointment(
      Map<String, dynamic> appointmentData, String accessToken) async {
    final client = await _getClient();
    try {
      final response = await client
          .post(
        Uri.parse('$_baseUrl/api/appointment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
        body: jsonEncode(appointmentData),
      )
          .timeout(const Duration(seconds: 15));


      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create appointment: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating appointment: $e');
    } finally {
      client.close();
    }
  }

  static Future<String> fetchMeetLink({String? topic}) async {
    final client = await _getClient();
    try {
      final uri = Uri.parse('$_baseUrl/api/helpper/meet-link')
          .replace(queryParameters: topic != null ? {'topic': topic} : null);
      final response = await client
          .get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 15));


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['meetingUrl'] != null) {
          return data['meetingUrl'] as String;
        } else {
          throw Exception('Invalid meet link response: No "meetingUrl" field found');
        }
      } else {
        throw Exception('Failed to fetch meet link: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching meet link: $e');
    } finally {
      client.close();
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAppointmentsByUserId({
    required String userId,
    int pageIndex = 0,
    int pageSize = 10,
    String searchString = '',
    String appointmentStatusEnum = '',
    String appointmentTypeEnum = '',
    bool isDescending = false,
  }) async {
    final client = await _getClient();
    try {
      final uri = Uri.parse('$_baseUrl/api/appointment/pagination')
          .replace(queryParameters: {
        'userId': userId,
        'pageIndex': pageIndex.toString(),
        'pageSize': pageSize.toString(),
        'searchString': searchString,
        'appointmentStatusEnum': appointmentStatusEnum,
        'appointmentTypeEnum': appointmentTypeEnum,
        'isDescending': isDescending.toString(),
      });

      final storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      final response = await client
          .get(
        uri,
        headers: headers,
      )
          .timeout(const Duration(seconds: 15));


      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody.isEmpty) {
          return [];
        }
        final decodedResponse = jsonDecode(responseBody);
        if (decodedResponse is List) {
          return List<Map<String, dynamic>>.from(decodedResponse);
        } else if (decodedResponse is Map && decodedResponse['items'] is List) {
          return List<Map<String, dynamic>>.from(decodedResponse['items']);
        } else {
          throw Exception('Unexpected response format: Expected a list or a map with "items" list');
        }
      } else {
        throw Exception(
            'Failed to fetch appointments: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    } finally {
      client.close();
    }
  }
}