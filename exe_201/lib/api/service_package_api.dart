import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ServicePackageApi {
  static const String _baseUrl =
      'https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net';
  static const storage = FlutterSecureStorage();

  static http.Client _getClient() {
    return http.Client();
  }

  static Future<String?> _refreshToken() async {
    final client = _getClient();
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      if (refreshToken == null) return null;

      final response = await client
          .post(
        Uri.parse('$_baseUrl/api/auth/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      )
          .timeout(const Duration(seconds: 15));


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'] as String?;
        if (newAccessToken != null) {
          await storage.write(key: 'access_token', value: newAccessToken);
          return newAccessToken;
        }
      }
      return null;
    } catch (e) {
      return null;
    } finally {
      client.close();
    }
  }

  static Future<List<Map<String, dynamic>>> fetchServicePackages({
    String? searchString,
    int? pageIndex,
    int? pageSize,
    bool? isDescending,
    String? pagingPackageEnum,
  }) async {
    final client = _getClient();
    try {
      final queryParams = {
        if (searchString != null && searchString.isNotEmpty) 'searchString': searchString,
        'pageIndex': (pageIndex ?? 1).toString(),
        'pageSize': (pageSize ?? 10).toString(),
        'isDescending': (isDescending ?? false).toString().toLowerCase(),
        if (pagingPackageEnum != null && pagingPackageEnum.isNotEmpty)
          'pagingPackageEnum': pagingPackageEnum,
      };
      final url = Uri.parse('$_baseUrl/api/service-package').replace(queryParameters: queryParams);

      var accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        throw Exception('No access token found. Please log in again.');
      }

      var response = await client
          .get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 15));


      if (response.statusCode == 401) {
        accessToken = await _refreshToken();
        if (accessToken == null) {
          throw Exception('Unauthorized: Invalid or expired access token. Please log in again.');
        }
        response = await client
            .get(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )
            .timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['items'] ?? []);
      } else {
        throw Exception(
            'Failed to load service packages (Status: ${response.statusCode}) - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching service packages: $e');
    } finally {
      client.close();
    }
  }

  static Future<List<Map<String, dynamic>>> fetchDeals(String packageId) async {
    final client = _getClient();
    try {
      final url = Uri.parse('$_baseUrl/api/service-package/deal/$packageId');

      var accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        throw Exception('No access token found. Please log in again.');
      }

      var response = await client
          .get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 15));


      if (response.statusCode == 401) {
        accessToken = await _refreshToken();
        if (accessToken == null) {
          throw Exception('Unauthorized: Invalid or expired access token. Please log in again.');
        }
        response = await client
            .get(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )
            .timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else if (response.statusCode == 404) {
        throw Exception(
            'Deals not found for package ID: $packageId. Please check the package ID or server configuration.');
      } else {
        throw Exception('Failed to load deals (Status: ${response.statusCode}) - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching deals: $e');
    } finally {
      client.close();
    }
  }

  static Future<String> claimPackage(String packageId, String? dealId, int monthNumber) async {
    final client = _getClient();
    try {
      final url = Uri.parse('$_baseUrl/api/payment/payos/service-package');

      var accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        throw Exception('No access token found. Please log in again.');
      }

      final body = jsonEncode({
        'monthNumber': monthNumber,
        'packageId': packageId,
        if (dealId != null) 'dealId': dealId,
      });

      var response = await client
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
        body: body,
      )
          .timeout(const Duration(seconds: 15));


      if (response.statusCode == 401) {
        accessToken = await _refreshToken();
        if (accessToken == null) {
          throw Exception('Unauthorized: Invalid or expired access token. Please log in again.');
        }
        response = await client
            .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
          body: body,
        )
            .timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        String paymentUrl = response.body.trim(); // Start with raw response

        // Remove quotation marks from JSON string
        paymentUrl = paymentUrl.replaceAll('"', '').trim();

        // Validate and ensure a single valid URL
        final uri = Uri.tryParse(paymentUrl);
        if (uri != null && uri.hasScheme) {
          return paymentUrl; // Return as-is if it's a valid URL
        } else {
          // If no scheme, prepend the PayOS base URL
          paymentUrl = 'https://pay.payos.vn/$paymentUrl';
          final validatedUri = Uri.tryParse(paymentUrl);
          if (validatedUri != null && validatedUri.hasScheme) {
            return paymentUrl;
          }
        }
        throw Exception('Invalid payment URL format: $paymentUrl');
      } else if (response.statusCode == 404 && response.body.contains('Deal not found')) {
        throw Exception('Deal not found. Please provide a valid dealId or check with the server.');
      } else if (response.statusCode == 400) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
            'Validation error: ${errorBody['title']} - ${errorBody['errors'] ?? errorBody['message']}');
      } else {
        throw Exception('Failed to claim package (Status: ${response.statusCode}) - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error claiming package: $e');
    } finally {
      client.close();
    }
  }
}