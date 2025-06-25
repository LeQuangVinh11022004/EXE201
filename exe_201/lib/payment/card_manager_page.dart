import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '/nav/bottom_nav_bar.dart'; // Import BottomNavBar
import '../auth/login.dart'; // Import LoginScreen để xử lý đăng xuất

class CardManagerPage extends StatefulWidget {
  const CardManagerPage({super.key});

  @override
  State<CardManagerPage> createState() => _CardManagerPageState();
}

class _CardManagerPageState extends State<CardManagerPage> {
  final storage = const FlutterSecureStorage();
  String? userId;
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> transactions = [];
  int pageIndex = 1;
  int pageSize = 10;
  int totalPagesCount = 1;
  bool hasNext = false;
  bool hasPrevious = false;

  // Constant base URL for API
  static const String _baseUrl = 'https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net';

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchTransactions();
  }

  // Hàm tạo HttpClient không cần SSL bypass
  http.Client _getClient() {
    return http.Client();
  }

  // Refresh access token
  Future<String?> _refreshToken() async {
    final client = _getClient();
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      if (refreshToken == null) return null;

      final response = await client.post(
        Uri.parse('$_baseUrl/api/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

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
      print('Error refreshing token: $e');
      return null;
    } finally {
      client.close();
    }
  }

  // Hàm định dạng ngày tháng
  String formatDate(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate).toLocal();
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      final hour = (dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12).toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$day.$month.$year - $hour:$minute $period';
    } catch (e) {
      return 'N/A';
    }
  }

  // Hàm định dạng số tiền
  String formatAmount(double amount) {
    final formattedAmount = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
    return '-$formattedAmount VND'; // Giả sử giao dịch là chi tiêu (dấu âm)
  }

  // Hàm lấy userId và gọi API để lấy danh sách giao dịch
  Future<void> _loadUserIdAndFetchTransactions({
    int? pageIndex,
    int? pageSize,
  }) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final id = await storage.read(key: 'user_id');
    var accessToken = await storage.read(key: 'access_token');

    if (accessToken == null || id == null) {
      setState(() {
        userId = id;
        isLoading = false;
        errorMessage = 'User ID or access token not found.';
      });
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
      return;
    }

    try {
      pageIndex = pageIndex ?? this.pageIndex;
      pageSize = pageSize ?? this.pageSize;

      final client = _getClient();
      var queryParameters = {
        'pageIndex': pageIndex.toString(),
        'pageSize': pageSize.toString(),
        'isDescending': 'false',
        'startDate': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'endDate': DateTime.now().toIso8601String(),
        if (id.isNotEmpty) 'userId': id,
      };
      var uri = Uri.parse('$_baseUrl/api/payment/transaction/fillter').replace(queryParameters: queryParameters);
      print('Calling API with URL: $uri');
      var response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 401) {
        accessToken = await _refreshToken();
        if (accessToken == null) {
          throw Exception('Unauthorized: Invalid or expired access token. Please log in again.');
        }
        response = await client.get(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response: $data');
        setState(() {
          userId = id;
          transactions = data['items'] ?? [];
          this.pageIndex = data['pageIndex'] ?? pageIndex;
          this.pageSize = pageSize!;
          totalPagesCount = data['totalPagesCount'] ?? 1;
          hasNext = data['next'] ?? false;
          hasPrevious = data['previous'] ?? false;
          isLoading = false;
        });
      } else {
        print('Failed to fetch transactions: ${response.statusCode} - ${response.body}');
        setState(() {
          userId = id;
          isLoading = false;
          errorMessage = 'Failed to fetch transactions: ${response.statusCode} - ${response.body}';
        });
        if (response.statusCode == 401 || response.statusCode == 403) {
          await storage.delete(key: 'access_token');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() {
        userId = id;
        isLoading = false;
        errorMessage = 'Failed to load transactions: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.pink[25],
        elevation: 0,
        title: const Text(
          'Manager Card',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await storage.delete(key: 'access_token');
              await storage.delete(key: 'user_id');
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (errorMessage != null)
                Center(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else if (transactions.isEmpty)
                  const Center(child: Text('No transactions found.'))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return Column(
                        children: [
                          _buildTransactionCard(
                            name: transaction['transferAccountName']?.toString() ?? 'Unknown',
                            date: formatDate(transaction['createdTime']?.toString() ?? ''),
                            amount: formatAmount(transaction['amount']?.toDouble() ?? 0.0),
                            avatarUrl: transaction['avatarUrl']?.toString() ?? 'https://via.placeholder.com/150',
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    },
                  ),
              const SizedBox(height: 10),
              // Phân trang
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: hasPrevious
                        ? () {
                      _loadUserIdAndFetchTransactions(pageIndex: pageIndex - 1);
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasPrevious ? Colors.blue : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Previous',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text('Page $pageIndex of $totalPagesCount'),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: hasNext
                        ? () {
                      _loadUserIdAndFetchTransactions(pageIndex: pageIndex + 1);
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasNext ? Colors.blue : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildTransactionCard({
    required String name,
    required String date,
    required String amount,
    required String avatarUrl,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(avatarUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}