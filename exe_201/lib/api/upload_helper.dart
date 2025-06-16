import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/api/account_api.dart';

class UploadHelper {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> uploadAvatar(File imageFile) async {
    String? accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      throw Exception('Access token not found. Please log in again.');
    }

    try {
      final uploadResponse = await AccountApi.uploadAvatar(
        accessToken: accessToken,
        file: imageFile,
      );


      if (uploadResponse['statusCode'] == 200) {
        final responseBody = uploadResponse['body'];
        String? avatarUrl;

        if (responseBody is String) {
          avatarUrl = responseBody; // Raw URL (e.g., https://res.cloudinary.com/...)
        } else if (responseBody is Map) {
          avatarUrl = responseBody['avatarUrl'] ?? responseBody['avatar']; // JSON response
        }

        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          return avatarUrl;
        } else {
          final userResponse = await AccountApi.getCurrentUser(accessToken);
          if (userResponse['statusCode'] == 200) {
            return userResponse['body']['avatar'];
          } else {
            throw Exception('Failed to fetch updated avatar URL: ${userResponse['body'] ?? 'Unknown error'}');
          }
        }
      } else if (uploadResponse['statusCode'] == 401) {
        throw Exception('Session expired. Please log in again.');
      } else {
        throw Exception('Failed to upload avatar: ${uploadResponse['body'] ?? 'Unknown error'}');
      }
    } catch (e) {
      rethrow;
    }
  }
}