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

class DoctorChatPage extends StatefulWidget {
  final String doctorName;
  final String chatHubId;
  final VoidCallback onClose;

  const DoctorChatPage({
    super.key,
    required this.doctorName,
    required this.chatHubId,
    required this.onClose,
  });

  @override
  _DoctorChatPageState createState() => _DoctorChatPageState();
}

class _DoctorChatPageState extends State<DoctorChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final storage = const FlutterSecureStorage();
  bool isLoading = false;
  late SignalRService signalR;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    signalR = SignalRService();
    signalR.onMessageReceived = _handleIncomingMessage;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initChat();
    });
  }

  Future<void> _initChat() async {
    setState(() => isLoading = true);
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      _showSnackBar("Please login to continue");
      setState(() => isLoading = false);
      return;
    }

    final userResponse = await AccountApi.getCurrentUser(accessToken);
    if (userResponse['statusCode'] != 200) {
      _showSnackBar("Failed to fetch user data");
      setState(() => isLoading = false);
      return;
    }
    currentUserId = userResponse['body']['id'] as String?;

    await _connectSignalR();
    await _fetchInitialMessages();
    setState(() => isLoading = false);
  }

  Future<void> _connectSignalR() async {
    if (!signalR.isConnected) {
      await signalR.connect();
    }
    await signalR.joinChatHub(widget.chatHubId);
  }

  void _handleIncomingMessage(Map<String, dynamic> message) {
    final now = DateTime.now();
    setState(() {
      _messages.add({
        'text': message['content'] ?? '',
        'senderId': message['senderId'],
        'time': DateFormat('d MMM yyyy HH:mm').format(now),
      });
    });
    _scrollToBottom();
  }

  Future<String?> _getAccessToken() async {
    return await storage.read(key: 'access_token');
  }

  Future<void> _fetchInitialMessages() async {
    setState(() => isLoading = false);
    try {
      final response = await ChatApi.fetchChatHubById(widget.chatHubId);
      if (response['statusCode'] == 200) {
        final chatMessages = response['body']['chatMessages'] as List<dynamic>;
        setState(() {
          _messages.clear();
          _messages.addAll(chatMessages.reversed.map((msg) {
            final createdTime = msg['createdTime'] as String?;
            final time = createdTime != null
                ? DateFormat('d MMM yyyy HH:mm').format(DateTime.parse(createdTime))
                : DateFormat('d MMM yyyy HH:mm').format(DateTime.now());
            return {
              'text': msg['content'] ?? '',
              'senderId': msg['senderId'],
              'time': time,
            };
          }).toList());
        });
        _scrollToBottom();
      } else {
        throw Exception('Failed to fetch messages: ${response['statusCode']}');
      }
    } catch (e) {
      _showSnackBar('Error fetching messages: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      _showSnackBar("Please login to continue");
      return;
    }

    setState(() => isLoading = false);
    final url = Uri.parse(
      'https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net/api/chat/message',
    );
    final client = IOClient(HttpClient()..badCertificateCallback = (_, __, ___) => true);

    try {
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'chatHubId': widget.chatHubId,
          'content': text,
          'type': 'Text',
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _messages.add({
            'text': text,
            'senderId': currentUserId,
            'time': DateFormat('d MMM yyyy HH:mm').format(DateTime.now()),
          });
          _controller.clear();
        });
        _scrollToBottom();
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error sending message: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    signalR.leaveChatHub(widget.chatHubId);
    signalR.onMessageReceived = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                final msg = _messages[index];
                final isSentByCurrentUser = msg['senderId'] == currentUserId;
                return Align(
                  key: ValueKey(index), // Tối ưu render
                  alignment: isSentByCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSentByCurrentUser ? Colors.pink[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(msg['text']),
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
                  icon: isLoading ? const CircularProgressIndicator(strokeWidth: 2) : const Icon(Icons.send),
                  onPressed: isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}