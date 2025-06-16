import 'package:exe_201/chat/chat_page.dart';
import 'package:flutter/material.dart';
import '/nav/bottom_nav_bar.dart';
import '../api/account_api.dart'; // For getCurrentUser
import '../api/chat_api.dart'; // For fetchChatHub
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  List<Map<String, dynamic>>? chatHubData; // Lưu danh sách chatHub
  bool isLoading = true;
  final storage = const FlutterSecureStorage(); // Khởi tạo storage

  @override
  void initState() {
    super.initState();
    _fetchChatHub();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<String?> _getAccessToken() async {
    final token = await storage.read(key: 'access_token'); // Đọc token với key đúng
    if (token == null) {
    }
    return token;
  }

  Future<void> _fetchChatHub() async {
    setState(() => isLoading = true);
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to continue')),
        );
        throw Exception('Access token not found for user data');
      }

      final userData = await AccountApi.getCurrentUser(accessToken);
      if (userData['statusCode'] != 200) {
        throw Exception('Failed to fetch user data: ${userData['statusCode']} - ${userData['body'] ?? 'No response body'}');
      }
      final userId = userData['body']['id'] as String;

      final chatHubResponse = await ChatApi.fetchChatHub(userId);
      if (chatHubResponse['statusCode'] != 200) {
        throw Exception('Failed to fetch chat hub: ${chatHubResponse['statusCode']} - ${chatHubResponse['body'] ?? 'No response body'}');
      }

      setState(() {
        chatHubData = List<Map<String, dynamic>>.from(chatHubResponse['body']);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching chat hub: ${e.toString().replaceFirst('Exception: ', '')}'),
          behavior: SnackBarBehavior.floating,
        ),
      );

    }
  }

  void _showChat(String doctorName, String chatHubId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ChatPage(
        doctorName: doctorName,
        chatHubId: chatHubId,
        onClose: () => Navigator.pop(context), // Đảm bảo truyền đúng onClose
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[50],
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mom&Baby Chat Hubs',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildChatHubList(chatHubData),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2), // Assuming "Journal" tab (index 2)
    );
  }

  Widget _buildChatHubList(List<Map<String, dynamic>>? chatHubs) {
    if (chatHubs == null || chatHubs.isEmpty) {
      return const Center(child: Text('No chat hub data available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chatHubs.length,
      itemBuilder: (context, index) {
        final chatHub = chatHubs[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.chat),
            ),
            title: Text(
              'Chat Hub: ${chatHub['nameChatHub'] ?? 'Unnamed'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${chatHub['status'] ?? 'Unknown'}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.message),
              onPressed: () => _showChat(chatHub['nameChatHub'] ?? 'Unknown', chatHub['id']),
            ),
          ),
        );
      },
    );
  }
}