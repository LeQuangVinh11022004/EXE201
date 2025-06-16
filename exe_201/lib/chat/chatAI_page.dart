import 'package:flutter/material.dart';
import '/nav/bottom_nav_bar.dart'; // Import BottomNavBar

class ChatAIScreen extends StatefulWidget {
  const ChatAIScreen({super.key});

  @override
  _ChatAIScreenState createState() => _ChatAIScreenState();
}

class _ChatAIScreenState extends State<ChatAIScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Thêm ScrollController
  final List<Map<String, dynamic>> _messages = [
    {
      'text': "Hi, I just wanna know that,\nhow much time you'll be\nupdated.",
      'isSentByUser': false,
      'time': "10:52",
    },
    {
      'text': "MAYBE, NEARLY JULY, 2022",
      'isSentByUser': true,
      'time': "10:53",
    },
    {
      'text': "OKAY, I'M WAITING...",
      'isSentByUser': false,
      'time': "10:53",
    },
  ];

  @override
  void initState() {
    super.initState();
    // Cuộn đến tin nhắn cuối cùng khi màn hình được tải lần đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) return;

    setState(() {
      // Add user's message
      _messages.add({
        'text': _controller.text,
        'isSentByUser': true,
        'time': TimeOfDay.now().format(context),
      });

      // Cuộn đến tin nhắn cuối cùng sau khi thêm tin nhắn mới
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Simulate AI response after a short delay
      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          _messages.add({
            'text': "I'm processing your request. Please wait...",
            'isSentByUser': false,
            'time': TimeOfDay.now().format(context),
          });

          // Cuộn đến tin nhắn cuối cùng sau khi thêm tin nhắn AI
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        });
      });
    });

    _controller.clear();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose(); // Dispose ScrollController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[50],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.account_circle, color: Colors.black),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mom&Baby",
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
                Text(
                  "Helpy Online",
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.videocam, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController, // Gắn ScrollController vào ListView
                padding: EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: message['isSentByUser']
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            margin: EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: message['isSentByUser']
                                  ? Colors.black
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message['text'],
                              style: TextStyle(
                                color: message['isSentByUser']
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: message['isSentByUser']
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: message['isSentByUser'] ? 0 : 8,
                              right: message['isSentByUser'] ? 8 : 0,
                            ),
                            child: Text(
                              message['time'],
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            // Bottom input bar with padding to lift it above the BottomNavBar
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0), // Adjust this value to position above the BottomNavBar
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.mic, color: Colors.black),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: "Write now...",
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: Colors.black),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0), // Default to Home tab (index 0)
    );
  }
}