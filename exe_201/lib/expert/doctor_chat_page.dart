import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../api/chat_api.dart';
import '../api/account_api.dart';
import '../nav/bottom_nav_bar.dart';

class DoctorChatPage extends StatefulWidget {
  final String nameChatHub;
  final String chatHubId;
  final VoidCallback onClose;

  const DoctorChatPage({
    super.key,
    required this.nameChatHub,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      _fetchInitialMessages();
    });
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
            _messages.addAll(chatMessages.whereType<Map<String, dynamic>>().map((msg) {
              final createdTime = msg['createdTime'] as String?;
              final time = createdTime != null
                  ? DateFormat('d MMM yyyy HH:mm').format(DateTime.parse(createdTime))
                  : DateFormat('d MMM yyyy HH:mm').format(DateTime.now());
              return {
                'text': msg['content'] ?? 'No content',
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
      _showSnackBar('Error fetching messages: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      setState(() => isLoading = false);
      _scrollToBottom();
    }
  }

  Future<String?> _getAccessToken() async {
    return await storage.read(key: 'access_token');
  }

  Future<String?> _getCurrentUserId(String? accessToken) async {
    if (accessToken == null) return null;
    try {
      final response = await AccountApi.getCurrentUser(accessToken);
      return response['statusCode'] == 200 ? response['body']['id'] as String : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => isLoading = true);
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        _showSnackBar('Please login to continue');
        return;
      }

      final url = Uri.parse(
          'https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net/api/chat/message');
      final ioClient = HttpClient()..badCertificateCallback = (_, __, ___) => true;
      final client = IOClient(ioClient);

      final response = await client
          .post(
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
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final currentTime = DateFormat('d MMM yyyy HH:mm').format(DateTime.now());
        setState(() {
          _messages.add({
            'text': _controller.text.trim(),
            'isSentByUser': true,
            'time': currentTime,
          });
          _controller.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        });
        await _fetchInitialMessages();
      } else {
        throw Exception('Failed to send message: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Error sending message: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).snackBarTheme.contentTextStyle,
        ),
        behavior: Theme.of(context).snackBarTheme.behavior,
        backgroundColor: Theme.of(context).snackBarTheme.backgroundColor,
        shape: Theme.of(context).snackBarTheme.shape,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: screenHeight * 0.1,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.iconTheme?.color,
            size: screenWidth * 0.08,
          ),
          onPressed: widget.onClose,
        ),
        title: Padding(
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
          child: Row(
            children: [
              Icon(
                Icons.account_circle,
                color: Theme.of(context).appBarTheme.iconTheme?.color,
                size: screenWidth * 0.1,
              ),
              SizedBox(width: screenWidth * 0.03),
              Flexible( // Wrap Column with Flexible to prevent overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Customer: ${widget.nameChatHub}",
                      style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                        fontSize: screenWidth * 0.06,
                      ),
                      overflow: TextOverflow.ellipsis, // Truncate long text
                      maxLines: 1, // Limit to one line
                    ),
                    Text(
                      "Online",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.call,
              color: Theme.of(context).appBarTheme.iconTheme?.color,
              size: screenWidth * 0.09,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.videocam,
              color: Theme.of(context).appBarTheme.iconTheme?.color,
              size: screenWidth * 0.09,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(screenWidth * 0.04),
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final time = message['time'];
                  return Padding(
                    padding: EdgeInsets.only(bottom: screenWidth * 0.02),
                    child: Column(
                      children: [
                        Center(
                          child: Text(
                            time,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                              fontSize: screenWidth * 0.03,
                            ),
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.01),
                        Row(
                          mainAxisAlignment: message['isSentByUser']
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Card(
                                elevation: Theme.of(context).cardTheme.elevation,
                                shape: Theme.of(context).cardTheme.shape,
                                color: message['isSentByUser']
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surface,
                                child: Padding(
                                  padding: EdgeInsets.all(screenWidth * 0.03),
                                  child: Text(
                                    message['text'],
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: message['isSentByUser']
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: screenHeight * 0.02,
                left: screenWidth * 0.02,
                right: screenWidth * 0.02,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.mic,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: screenWidth * 0.07,
                      ),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: "Write now...",
                            border: InputBorder.none,
                            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.primary,
                        size: screenWidth * 0.07,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}