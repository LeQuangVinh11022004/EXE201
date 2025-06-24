import 'package:exe_201/chat/chat_page.dart';
import 'package:flutter/material.dart';
import '../service/signalRService.dart';
import '/nav/bottom_nav_bar.dart';
import '../api/account_api.dart';
import '../api/chat_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  List<Map<String, dynamic>>? chatHubData;
  bool isLoading = true;
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchChatHub();
  }

  Future<String?> _getAccessToken() async {
    return await storage.read(key: 'access_token');
  }

  Future<void> _fetchChatHub() async {
    setState(() => isLoading = true);
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        throw Exception('Please login to continue');
      }

      final userData = await AccountApi.getCurrentUser(accessToken);
      if (userData['statusCode'] != 200) {
        throw Exception('Failed to fetch user data');
      }
      final userId = userData['body']['id'] as String;

      final chatHubResponse = await ChatApi.fetchChatHub(userId);
      if (chatHubResponse['statusCode'] != 200) {
        throw Exception('Failed to fetch chat hub');
      }

      setState(() {
        chatHubData = List<Map<String, dynamic>>.from(chatHubResponse['body']);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  void _showChat(String doctorName, String chatHubId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final signalR = SignalRService();
      if (!signalR.isConnected) {
        await signalR.connect();
      }

      await signalR.joinChatHub(chatHubId);
      Navigator.pop(context);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => ChatPage(
          doctorName: doctorName,
          chatHubId: chatHubId,
          onClose: () async {
            await signalR.leaveChatHub(chatHubId);
            Navigator.pop(context);
          },
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      String errorMessage = e.toString().contains('503')
          ? 'Server is currently unavailable. Please try again later.'
          : e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to connect: $errorMessage'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _showChat(doctorName, chatHubId),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[50],
        centerTitle: true,
        title: const Text(
          'Mom&Baby Chat Hubs',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchChatHub,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildChatHubList(chatHubData),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildChatHubList(List<Map<String, dynamic>>? chatHubs) {
    if (chatHubs == null || chatHubs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No chat hubs available', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _fetchChatHub, child: const Text('Refresh')),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chatHubs.length,
      itemBuilder: (context, index) {
        final chatHub = chatHubs[index];
        final hubName = chatHub['nameChatHub'] ?? 'Unnamed Hub';
        final status = chatHub['status'] ?? 'Unknown';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: status.toLowerCase() == 'active' ? Colors.green[100] : Colors.orange[100],
              child: Icon(Icons.chat, color: status.toLowerCase() == 'active' ? Colors.green[700] : Colors.orange[700]),
            ),
            title: Text('Chat Hub: $hubName', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Status: $status'),
            trailing: IconButton(
              icon: const Icon(Icons.message),
              onPressed: () => _showChat(hubName, chatHub['id']),
              tooltip: 'Open chat',
            ),
          ),
        );
      },
    );
  }
}