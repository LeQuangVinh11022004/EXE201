import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/account_api.dart';
import '../api/chat_api.dart';
import 'doctor_chat_page.dart'; // Import DoctorChatPage

class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({super.key});

  @override
  _DoctorAppointmentsPageState createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  List<Map<String, dynamic>>? chatHubData;
  bool isLoading = true;
  final storage = const FlutterSecureStorage();

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
    final token = await storage.read(key: 'access_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to continue')),
      );
    }
    return token;
  }

  Future<void> _fetchChatHub() async {
    setState(() => isLoading = true);
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        throw Exception('Access token not found for doctor data');
      }

      final userData = await AccountApi.getCurrentUser(accessToken);
      if (userData['statusCode'] != 200) {
        throw Exception('Failed to fetch doctor data: ${userData['statusCode']} - ${userData['body'] ?? 'No response body'}');
      }
      final doctorId = userData['body']['id'] as String;

      final chatHubResponse = await ChatApi.fetchChatHubForDoctor(doctorId);
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
      builder: (context) => DoctorChatPage(
        doctorName: doctorName,
        chatHubId: chatHubId,
        onClose: () => Navigator.pop(context),
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
          'Doctor Chat Hubs',
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
              'Chat with: ${chatHub['nameChatHub'] ?? 'Unnamed'}',
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