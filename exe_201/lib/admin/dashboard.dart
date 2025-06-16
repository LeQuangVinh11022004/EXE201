import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as io_client;
import '../auth/login.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final storage = const FlutterSecureStorage();
  bool isLoading = false;
  List<dynamic> accounts = [];
  int totalItemsCount = 0;
  int pageIndex = 1;
  int pageSize = 10;
  int totalPagesCount = 1;
  bool hasNext = false;
  bool hasPrevious = false;
  String? errorMessage;

  // Controllers cho form cập nhật
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _sexController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAccountData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _sexController.dispose();
    super.dispose();
  }

  // Hàm tạo HttpClient với SSL bypass
  Future<http.Client> _getClient() async {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return io_client.IOClient(httpClient);
  }

  // Hàm gọi API /api/account để lấy danh sách tài khoản
  Future<void> fetchAccountData({
    int? pageIndex,
    int? pageSize,
  }) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    String? accessToken = await storage.read(key: 'access_token');

    if (accessToken == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    pageIndex = pageIndex ?? this.pageIndex;
    pageSize = pageSize ?? this.pageSize;

    final client = await _getClient();
    var queryParameters = {
      '_pageIndex': pageIndex.toString(),
      '_pageSize': pageSize.toString(),
    };
    var uri = Uri.parse('https://10.0.2.2:7015/api/account').replace(queryParameters: queryParameters);
    var response = await client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        accounts = data['items'] ?? [];
        totalItemsCount = data['totalItemsCount'] ?? 0;
        this.pageIndex = data['pageIndex'] ?? pageIndex;
        this.pageSize = pageSize!;
        totalPagesCount = data['totalPagesCount'] ?? 1;
        hasNext = data['next'] ?? false;
        hasPrevious = data['previous'] ?? false;
        isLoading = false;

   
      });
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to fetch accounts: ${response.statusCode} - ${response.body}';
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
  }

  // Hàm gọi API PUT /api/account/{id} để cập nhật thông tin tài khoản
  Future<void> updateAccount(String id, Map<String, dynamic> body) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    String? accessToken = await storage.read(key: 'access_token');

    if (accessToken == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    final client = await _getClient();
    var uri = Uri.parse('https://10.0.2.2:7015/api/account/$id');
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
    final encodedBody = jsonEncode(body);
    var response = await client.put(
      uri,
      headers: headers,
      body: encodedBody,
    );

    if (response.statusCode == 200) {
      setState(() {
        isLoading = false;
        errorMessage = 'Account updated successfully!';
      });
      fetchAccountData(); // Làm mới danh sách sau khi cập nhật
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to update account: ${response.statusCode} - ${response.body}';
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
  }

  // Hàm hiển thị form cập nhật tài khoản
  void showUpdateAccountDialog(BuildContext context, String id, Map<String, dynamic> account) {
    _fullNameController.text = account['fullName'] ?? '';
    _dateOfBirthController.text = account['dateOfBirth']?.toString().split('T')[0] ?? '';
    _sexController.text = account['sex'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
                keyboardType: TextInputType.datetime,
              ),
              DropdownButtonFormField<String>(
                value: _sexController.text.isEmpty ? null : _sexController.text,
                decoration: const InputDecoration(labelText: 'Sex'),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sexController.text = value ?? '';
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Validate dữ liệu trước khi gửi
              if (_fullNameController.text.isEmpty ||
                  _dateOfBirthController.text.isEmpty ||
                  _sexController.text.isEmpty) {
                setState(() {
                  errorMessage = 'Please fill in all fields';
                });
                Navigator.pop(context);
                return;
              }

              // Định dạng dateOfBirth thành ISO 8601
              String? formattedDateOfBirth;
              try {
                final dateParts = _dateOfBirthController.text.split('-');
                if (dateParts.length == 3) {
                  formattedDateOfBirth = '${_dateOfBirthController.text}T00:00:00.000Z';
                } else {
                  throw FormatException('Invalid date format');
                }
              } catch (e) {
                setState(() {
                  errorMessage = 'Invalid date format. Use YYYY-MM-DD';
                });
                Navigator.pop(context);
                return;
              }

              // Thử gửi body mà không có userUpdateDTO wrapper
              final body = {
                'Id': id, // Thêm Id vào body
                'FullName': _fullNameController.text,
                'DateOfBirth': formattedDateOfBirth,
                'Sex': _sexController.text,
                'Status': account['status'] ?? 'Active',
                'Avatar': account['avatar'] ?? null,
                'CreatedTime': account['createdTime'] ?? DateTime.now().toIso8601String(),
                'UpdatedTime': DateTime.now().toIso8601String(),
                if (account['expert'] != null) 'Expert': {
                  'Id': account['expert']['id'],
                  'Degree': account['expert']['degree'],
                  'Workplace': account['expert']['workplace'],
                  'Description': account['expert']['description'],
                },
              };
              updateAccount(id, body);
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Admin!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Total Accounts: $totalItemsCount'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Accounts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : accounts.isEmpty
                      ? const Center(child: Text('No accounts found.'))
                      : ListView.builder(
                          itemCount: accounts.length,
                          itemBuilder: (context, index) {
                            final account = accounts[index];
                            final isExpert = account['expert'] != null;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16.0),
                                title: Text(
                                  account['fullName'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text('Sex: ${account['sex'] ?? 'N/A'}'),
                                    Text('Status: ${account['status'] ?? 'N/A'}'),
                                    if (isExpert) ...[
                                      const SizedBox(height: 8),
                                      Text('Degree: ${account['expert']['degree'] ?? 'N/A'}'),
                                      Text('Workplace: ${account['expert']['workplace'] ?? 'N/A'}'),
                                    ],
                                  ],
                                ),
                                trailing: Icon(
                                  isExpert ? Icons.medical_services : Icons.person,
                                  color: isExpert ? Colors.green : Colors.grey,
                                ),
                                onTap: () {
                                  final accountId = account['id'];
                                  if (accountId != null) {
                                    showUpdateAccountDialog(context, accountId, account);
                                  }
                                },
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 10),
            // Phân trang
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: hasPrevious
                      ? () {
                          fetchAccountData(pageIndex: pageIndex - 1);
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
                          fetchAccountData(pageIndex: pageIndex + 1);
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
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}