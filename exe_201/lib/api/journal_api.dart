import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class JournalApi {
  static const storage = FlutterSecureStorage();
  static const String _baseUrl =
      'https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net';

  static Future<IOClient> _getClient() async {
    final httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    return IOClient(httpClient);
  }

  static Future<Map<String, dynamic>> getJournalEntries({
    int? pageIndex,
    int? pageSize,
    String? headOrContent,
    bool? isDescending,
  }) async {
    final url = Uri.parse('$_baseUrl/api/journal').replace(
      queryParameters: <String, String>{
        if (pageIndex != null) 'pageIndex': pageIndex.toString(),
        if (pageSize != null) 'pageSize': pageSize.toString(),
        if (headOrContent != null && headOrContent.trim().isNotEmpty)
          'headOrContent': headOrContent.trim(),
        if (isDescending != null) 'isDescending': isDescending.toString(),
      },
    );

    const int maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final accessToken = await storage.read(key: 'access_token');
        if (accessToken == null) {
          throw Exception('No access token found. Please log in again.');
        }

        final client = await _getClient();
        final response = await client
            .get(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
          },
        )
            .timeout(const Duration(seconds: 15));


        if (response.statusCode == 200) {
          final responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
          return {
            'statusCode': response.statusCode,
            'body': responseBody,
          };
        } else if (response.statusCode == 401) {
          throw Exception('Unauthorized: Invalid or expired access token. Please log in again.');
        } else if (response.statusCode == 404) {
          throw Exception('Journal endpoint not found (404). Please check the server configuration.');
        } else {
          throw Exception('Failed to fetch journal entries: ${response.body} (Status: ${response.statusCode})');
        }
      } on FormatException catch (e) {
        throw Exception('Failed to parse server response: $e');
      } on http.ClientException catch (e) {
        attempt++;
        if (attempt == maxRetries) {
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } on SocketException catch (e) {
        attempt++;
        if (attempt == maxRetries) {
          throw Exception('Failed to connect to the server after $maxRetries attempts: $e');
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } on TimeoutException catch (e) {
        attempt++;
        if (attempt == maxRetries) {
          throw Exception('Request timed out after $maxRetries attempts: $e');
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } catch (e) {
        throw Exception('Failed to fetch journal entries: $e');
      }
    }
    throw Exception('Failed to fetch journal entries after $maxRetries attempts');
  }

  static Future<Map<String, dynamic>> createJournalEntry({
    required String head,
    required String content,
    String? imagePath,
  }) async {
    final url = Uri.parse('$_baseUrl/api/journal');

    const int maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final accessToken = await storage.read(key: 'access_token');
        if (accessToken == null) {
          throw Exception('No access token found. Please log in again.');
        }

        if (head.trim().isEmpty) {
          throw Exception('Head cannot be empty.');
        }
        if (head.trim().length < 3) {
          throw Exception('Head must be at least 3 characters long.');
        }

        var request = http.MultipartRequest('POST', url)
          ..headers['Authorization'] = 'Bearer $accessToken'
          ..headers['Accept'] = 'application/json'
          ..fields['Head'] = head.trim()
          ..fields['Content'] = content.trim().isEmpty ? 'DefaultContent123' : content.trim()
          ..fields['UserId'] = (await storage.read(key: 'user_id')) ?? '125ad6c8-be95-4706-8593-08dd92e4ba56';

        if (imagePath != null && imagePath.isNotEmpty) {
          request.files.add(await http.MultipartFile.fromPath('Image', imagePath));
        }

        final client = await _getClient();
        final streamedResponse = await client.send(request).timeout(const Duration(seconds: 15));
        final response = await http.Response.fromStream(streamedResponse);


        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
          return {
            'statusCode': response.statusCode,
            'body': responseBody,
          };
        } else if (response.statusCode == 401) {
          throw Exception('Unauthorized: Invalid or expired access token. Please log in again.');
        } else if (response.statusCode == 400) {
          final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
          final errors = errorBody['errors'] != null
              ? errorBody['errors'].entries
              .map((e) => '${e.key}: ${e.value.join(', ')}')
              .join('; ')
              : errorBody['title'] ?? 'Invalid request';
          throw Exception('Bad request: $errors');
        } else {
          throw Exception('Failed to create journal entry: ${response.body} (Status: ${response.statusCode})');
        }
      } on FormatException catch (e) {
        throw Exception('Failed to parse server response: $e');
      } on http.ClientException catch (e) {
        attempt++;
        if (attempt == maxRetries) {
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } on SocketException catch (e) {
        attempt++;
        if (attempt == maxRetries) {
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } on TimeoutException catch (e) {
        attempt++;
        if (attempt == maxRetries) {
          throw Exception('Request timed out after $maxRetries attempts: $e');
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } catch (e) {
        throw Exception('Failed to create journal entry: $e');
      }
    }
    throw Exception('Failed to create journal entry after $maxRetries attempts');
  }

  static Future<Map<String, dynamic>> updateJournalEntry({
    required String journalId,
    required String head,
    required String content,
    String? imagePath,
  }) async {
    if (journalId.isEmpty) {
      throw Exception('Journal ID is empty. Cannot update entry.');
    }
    if (head.trim().isEmpty) {
      throw Exception('Head is required. Cannot update entry.');
    }

    final url = Uri.parse('$_baseUrl/api/journal/$journalId');

    const int maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final accessToken = await storage.read(key: 'access_token');
        if (accessToken == null) {
          throw Exception('No access token found. Please log in again.');
        }

        var request = http.MultipartRequest('PUT', url)
          ..headers['Authorization'] = 'Bearer $accessToken'
          ..headers['Accept'] = 'application/json'
          ..fields['Head'] = head.trim()
          ..fields['Content'] = content.trim().isEmpty ? 'DefaultContent123' : content.trim()
          ..fields['UserId'] = (await storage.read(key: 'user_id')) ?? '125ad6c8-be95-4706-8593-08dd92e4ba56';

        if (imagePath != null && imagePath.isNotEmpty) {
          if (imagePath.startsWith('http')) {
            request.fields['Image'] = imagePath;
          } else {
            request.files.add(await http.MultipartFile.fromPath('Image', imagePath));
          }
        }

        final client = await _getClient();
        final streamedResponse = await client.send(request).timeout(const Duration(seconds: 15));
        final response = await http.Response.fromStream(streamedResponse);


        if (response.statusCode == 200 || response.statusCode == 204) {
          final responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
          return {
            'statusCode': response.statusCode,
            'body': responseBody,
          };
        } else if (response.statusCode == 401) {
          throw Exception('Unauthorized: Invalid or expired access token. Please log in again.');
        } else if (response.statusCode == 400) {
          final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
          final errors = errorBody['errors'] != null
              ? errorBody['errors'].entries
              .map((e) => '${e.key}: ${e.value.join(', ')}')
              .join('; ')
              : errorBody['title'] ?? 'Invalid request';
          throw Exception('Bad request: $errors');
        } else {
          throw Exception('Failed to update journal entry: ${response.body} (Status: ${response.statusCode})');
        }
      } on FormatException catch (e) {
        throw Exception('Failed to parse server response: $e');
      } on http.ClientException catch (e) {
        attempt++;
        if (attempt == maxRetries) {
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } on SocketException catch (e) {
        attempt++;
        if (attempt == maxRetries) {
          throw Exception('Failed to connect to the server after $maxRetries attempts: $e');
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } on TimeoutException catch (e) {
        attempt++;
        if (attempt == maxRetries) {
          throw Exception('Request timed out after $maxRetries attempts: $e');
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } catch (e) {
        throw Exception('Failed to update journal entry: $e');
      }
    }
    throw Exception('Failed to update journal entry after $maxRetries attempts');
  }

  static Future<Map<String, dynamic>> deleteJournalEntry({
    required String journalId,
  }) async {
    if (journalId.isEmpty) {
      throw Exception('Journal ID is empty. Cannot delete entry.');
    }

    final url = Uri.parse('$_baseUrl/api/journal/$journalId');

    const int maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final accessToken = await storage.read(key: 'access_token');
        if (accessToken == null) {
          throw Exception('No access token found. Please log in again.');
        }

        final client = await _getClient();
        final response = await client
            .delete(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
          },
        )
            .timeout(const Duration(seconds: 15));


        if (response.statusCode == 200 || response.statusCode == 204) {
          final responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
          return {
            'statusCode': response.statusCode,
            'body': responseBody,
          };
        } else if (response.statusCode == 401) {
          throw Exception('Unauthorized: Invalid or expired access token. Please log in again.');
        } else if (response.statusCode == 404) {
          throw Exception('Journal entry not found (404).');
        } else {
          throw Exception('Failed to delete journal entry: ${response.body} (Status: ${response.statusCode})');
        }
      } on FormatException catch (e) {
        throw Exception('Failed to parse server response: $e');
      } on http.ClientException catch (e) {
        attempt++;
        if (attempt == maxRetries) {
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } on SocketException catch (e) {
        attempt++;
        if (attempt == maxRetries) {
          throw Exception('Failed to connect to the server after $maxRetries attempts: $e');
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } on TimeoutException catch (e) {
        attempt++;
        if (attempt == maxRetries) {
          throw Exception('Request timed out after $maxRetries attempts: $e');
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } catch (e) {
        throw Exception('Failed to delete journal entry: $e');
      }
    }
    throw Exception('Failed to delete journal entry after $maxRetries attempts');
  }
}