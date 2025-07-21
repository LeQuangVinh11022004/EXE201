import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import '../api/chat_api.dart';
import '../api/account_api.dart';
import '../nav/bottom_nav_bar.dart';
import '../service/signalRService.dart';
import 'package:exe_201/config.dart';
class ChatPage extends StatefulWidget {
  final String doctorName;
  final String chatHubId;
  final VoidCallback onClose;


  const ChatPage({
    super.key,
    required this.doctorName,
    required this.chatHubId,
    required this.onClose,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final storage = const FlutterSecureStorage();
  bool isLoading = false;
  late SignalRService signalR;
  final Set<String> _messageKeys = {};

  @override
  void initState() {
    super.initState();
    signalR = SignalRService();
    signalR.onMessageReceived = _handleIncomingMessage;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchInitialMessages();
      _scrollToBottom();
    });
  }

  void _handleIncomingMessage(Map<String, dynamic> message) {
    final content = message['content'] ?? '';
    final createdTime = message['createdTime'] ?? '';
    final key = '$content|$createdTime';

    if (_messageKeys.contains(key)) return; // tránh trùng lặp

    _messageKeys.add(key);

    final time = createdTime != ''
        ? DateFormat('d MMM yyyy HH:mm').format(DateTime.parse(createdTime))
        : DateFormat('d MMM yyyy HH:mm').format(DateTime.now());

    setState(() {
      _messages.add({
        'text': content,
        'isSentByUser': false,
        'time': time,
      });
    });
    _scrollToBottom();
  }

  Future<String?> _getAccessToken() async {
    return await storage.read(key: 'access_token');
  }

  Future<String?> _getCurrentUserId(String? accessToken) async {
    if (accessToken == null) return null;
    try {
      final response = await AccountApi.getCurrentUser(accessToken);
      return response['statusCode'] == 200 ? response['body']['id'] as String : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchInitialMessages() async {
    setState(() => isLoading = true);
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        _showSnackBar('Please login to continue');
        return;
      }

      final response = await ChatApi.fetchChatHubById(widget.chatHubId);
      if (response['statusCode'] == 200) {
        final chatHub = response['body'];
        if (chatHub['chatMessages'] != null && chatHub['chatMessages'] is List) {
          final userId = await _getCurrentUserId(accessToken);
          final chatMessages = chatHub['chatMessages'] as List<dynamic>;
          setState(() {
            _messages.clear();
            _messages.addAll(chatMessages.reversed.map((msg) {
              final createdTime = msg['createdTime'] as String?;
              final time = createdTime != null
                  ? DateFormat('d MMM yyyy HH:mm').format(DateTime.parse(createdTime))
                  : DateFormat('d MMM yyyy HH:mm').format(DateTime.now());
              return {
                'text': msg['content'] ?? '',
                'isSentByUser': userId != null && msg['senderId'] == userId,
                'time': time,
              };
            }).toList());
          });
        }
      } else {
        throw Exception('Failed to fetch messages: ${response['statusCode']}');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        _showSnackBar('Please login to continue');
        return;
      }

      final url = Uri.parse(
          '${AppConfig.apiBaseUrl}/api/chat/message');
      final ioClient = HttpClient()..badCertificateCallback = (_, __, ___) => true;
      final client = IOClient(ioClient);

      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'chatHubId': widget.chatHubId,
          'content': _controller.text.trim(),
          'type': 'Text',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final currentTime = DateFormat('d MMM yyyy HH:mm').format(DateTime.now());
        setState(() {
          _messages.add({
            'text': _controller.text.trim(),
            'isSentByUser': true,
            'time': currentTime,
          });
          _controller.clear();
          isLoading = false; // Gộp isLoading vào đây
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      } else {
        throw Exception('Failed to send message: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Error sending message: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }



  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    signalR.onMessageReceived = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // UI phần build giữ nguyên
    // Nếu cần t có thể gửi riêng phần `build()` đã lược gọn
    return Scaffold(
      appBar: AppBar(
        title: Text("Dr. ${widget.doctorName}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onClose,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message['isSentByUser']
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Card(
                    color: message['isSentByUser'] ? Colors.pink[100] : Colors.grey[300],
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(message['text']),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: "Type a message"),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}
