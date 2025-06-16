import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';

class DoctorApi {
  static const String baseUrl =
      'https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net';

  static Future<IOClient> _getClient() async {
    final httpClient = HttpClient();
    return IOClient(httpClient); // Removed badCertificateCallback for secure SSL
  }

  static Future<Map<String, dynamic>> fetchDoctors({
    String? searchString,
    int? pageIndex,
    int? pageSize,
    bool? isDescending,
    String? status,
  }) async {
    IOClient? client;
    try {
      final queryParameters = {
        if (searchString != null) 'searchString': searchString,
        if (pageIndex != null) 'pageIndex': pageIndex.toString(),
        if (pageSize != null) 'pageSize': pageSize.toString(),
        if (isDescending != null) 'isDescending': isDescending.toString(),
        if (status != null) 'status': status,
      };

      final uri = Uri.parse('$baseUrl/api/expert').replace(queryParameters: queryParameters);
      client = await _getClient();


      final response = await client
          .get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out after 30 seconds');
      });


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        return {
          'doctors': items.map((doctor) => {
            'id': doctor['id']?.toString() ?? '',
            'name': doctor['user']['fullName']?.toString() ?? 'Unknown Doctor',
            'description': doctor['description']?.toString() ?? '',
            'imagePath': doctor['user']['avatar']?.toString() ?? 'assets/placeholder_doctor.jpg',
            'age': _calculateAge(doctor['user']['dateOfBirth']?.toString()),
            'phone': '',
            'specialty': doctor['specialty']?.toString() ?? 'N/A',
            'degree': doctor['degree']?.toString() ?? 'N/A',
            'workplace': doctor['workplace']?.toString() ?? 'N/A',
            'sex': doctor['user']['sex']?.toString() ?? 'N/A',
            'status': doctor['status']?.toString() ?? 'N/A',
            'createdTime': doctor['user']['createdTime']?.toString() ?? 'N/A',
            'updatedTime': doctor['user']['updatedTime']?.toString() ?? 'N/A',
          }).toList(),
          'totalItemsCount': data['totalItemsCount'] ?? 0,
          'pageSize': data['pageSize'] ?? 10,
          'pageIndex': data['pageIndex'] ?? 1,
          'totalPagesCount': data['totalPagesCount'] ?? 1,
          'next': data['next'] ?? false,
          'previous': data['previous'] ?? false,
        };
      } else {
        throw Exception('Failed to load doctors: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      throw Exception('Error fetching doctors: $e');
    } finally {
      client?.close();
    }
  }

  static Future<Map<String, dynamic>> fetchDoctorById(String expertId) async {
    IOClient? client;
    try {
      final uri = Uri.parse('$baseUrl/api/expert/$expertId');
      client = await _getClient();


      final response = await client
          .get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out after 30 seconds');
      });


      if (response.statusCode == 200) {
        final doctor = jsonDecode(response.body);
        return {
          'id': doctor['id']?.toString() ?? '',
          'name': doctor['user']['fullName']?.toString() ?? 'Unknown Doctor',
          'description': doctor['description']?.toString() ?? 'N/A',
          'imagePath': doctor['user']['avatar']?.toString() ?? 'assets/placeholder_doctor.jpg',
          'age': _calculateAge(doctor['user']['dateOfBirth']?.toString()),
          'phone': '',
          'specialty': doctor['specialty']?.toString() ?? 'N/A',
          'degree': doctor['degree']?.toString() ?? 'N/A',
          'workplace': doctor['workplace']?.toString() ?? 'N/A',
          'sex': doctor['user']['sex']?.toString() ?? 'N/A',
          'status': doctor['status']?.toString() ?? 'N/A',
          'createdTime': doctor['user']['createdTime']?.toString() ?? 'N/A',
          'updatedTime': doctor['user']['updatedTime']?.toString() ?? 'N/A',
        };
      } else {
        throw Exception('Failed to load doctor: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      throw Exception('Error fetching doctor: $e');
    } finally {
      client?.close();
    }
  }

  static String _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null) return 'N/A';
    try {
      final date = DateTime.parse(dateOfBirth).toLocal();
      final now = DateTime.now();
      int age = now.year - date.year;
      if (now.month < date.month || (now.month == date.month && now.day < date.day)) {
        age--;
      }
      return age.toString();
    } catch (e) {
      return 'N/A';
    }
  }
}