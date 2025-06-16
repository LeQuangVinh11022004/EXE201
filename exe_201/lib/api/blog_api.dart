import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:app_links/app_links.dart';

class BlogApi {
  static const String baseUrl =
      'https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net';
  static http.Client? _client;
  static AppLinks? _appLinks;

  static Future<void> initializeAppLinks() async {
    _appLinks = AppLinks();
    _appLinks?.stringLinkStream.listen((String? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {});
  }

  static void _handleDeepLink(String uri) {
    final uriObj = Uri.parse(uri);
    if (uriObj.pathSegments.contains('blog')) {
    } else if (uriObj.pathSegments.contains('upload')) {
    }
  }

  static Future<http.Client> _getClient() async {
    if (_client == null) {
      final httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);
      _client = IOClient(httpClient);
    }
    return _client!;
  }

  static void disposeClient() {
    _client?.close();
    _client = null;
  }

  static Future<Map<String, dynamic>> uploadImage({
    required String accessToken,
    required String filePath,
  }) async {
    final client = await _getClient();
    try {
      final uri = Uri.parse('$baseUrl/api/helpper/upload');
      var request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await client.send(request).timeout(const Duration(seconds: 15));
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return {
          'statusCode': response.statusCode,
          'body': responseBody,
        };
      } else {
        throw Exception('Failed to upload image: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  static Future<Map<String, dynamic>> getBlogs({
    required String accessToken,
  }) async {
    final client = await _getClient();
    try {
      final uri = Uri.parse('$baseUrl/api/blog');
      final response = await client
          .get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return {
          'statusCode': response.statusCode,
          'body': jsonDecode(response.body),
        };
      } else {
        throw Exception('Failed to load blogs: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error loading blogs: $e');
    }
  }

  static Future<Map<String, dynamic>> createPost({
    required String accessToken,
    required String content,
    String? image,
  }) async {
    final client = await _getClient();
    try {
      final uri = Uri.parse('$baseUrl/api/blog');
      final body = {
        'content': content,
        'image': image ?? '',
      };

      final response = await client
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'statusCode': response.statusCode,
          'body': response.body.isNotEmpty ? jsonDecode(response.body) : {},
        };
      } else {
        throw Exception('Failed to create post: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating post: $e');
    }
  }

  static Future<Map<String, dynamic>> likeBlog({
    required String blogId,
    required String accessToken,
  }) async {
    final client = await _getClient();
    try {
      final uri = Uri.parse('$baseUrl/api/interaction/like/$blogId');
      final response = await client
          .post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'statusCode': response.statusCode,
          'body': response.body.isNotEmpty ? jsonDecode(response.body) : {},
        };
      } else {
        throw Exception('Failed to like blog: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error liking blog: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteLike({
    required String blogId,
    required String accessToken,
  }) async {
    final client = await _getClient();
    try {
      final uri = Uri.parse('$baseUrl/api/interaction/like/$blogId');
      final response = await client
          .delete(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'statusCode': response.statusCode,
          'body': response.body.isNotEmpty ? jsonDecode(response.body) : {},
        };
      } else {
        throw Exception('Failed to delete like: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting like: $e');
    }
  }

  static Future<Map<String, dynamic>> getLikedBlogs({
    required String userId,
    required String accessToken,
  }) async {
    final client = await _getClient();
    try {
      final uri = Uri.parse('$baseUrl/api/blog/liked?userId=$userId');
      final response = await client
          .get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return {
          'statusCode': response.statusCode,
          'body': body,
        };
      } else {
        throw Exception('Failed to get liked blogs: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting liked blogs: $e');
    }
  }

  static Future<Map<String, dynamic>> commentBlog({
    required String blogId,
    required String accessToken,
    required String content, // Nội dung bình luận
    required String userId,  // Giữ tham số này, nhưng không gửi trong body
  }) async {
    final client = await _getClient();
    try {
      final uri = Uri.parse('$baseUrl/api/interaction/comment/$blogId');
      final body = content.trim(); // Gửi chuỗi đơn làm body

      print('Sending comment request: $body'); // Debug log
      final response = await client
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          // userId không cần gửi trong body, có thể lấy từ token
        },
        body: jsonEncode(body), // Mã hóa chuỗi thành JSON
      )
          .timeout(const Duration(seconds: 15));

      print('Response status: ${response.statusCode}, body: ${response.body}'); // Debug log
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'statusCode': response.statusCode,
          'body': response.body.isNotEmpty ? jsonDecode(response.body) : {},
        };
      } else {
        throw Exception('Failed to comment blog: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in commentBlog: $e'); // Debug log
      throw Exception('Error commenting blog: $e');
    }
  }

  static Future<Map<String, dynamic>> getBlogById({
    required String id,
    required String accessToken,
  }) async {
    final client = await _getClient();
    try {
      final uri = Uri.parse('$baseUrl/api/blog/$id');
      final response = await client
          .get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 15));

      print('Response status: ${response.statusCode}, body: ${response.body}'); // Debug log
      if (response.statusCode == 200) {
        return {
          'statusCode': response.statusCode,
          'body': jsonDecode(response.body),
        };
      } else {
        throw Exception('Failed to get blog: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getBlogById: $e'); // Debug log
      throw Exception('Error getting blog: $e');
    }
  }
}