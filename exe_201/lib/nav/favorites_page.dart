import 'package:exe_201/chat/chatAI_page.dart';
import 'package:flutter/material.dart';
import './bottom_nav_bar.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  final List<Map<String, dynamic>> favoriteBlogs = const [
    {
      'title': 'Top 10 Tips for a Healthy Pregnancy',
      'summary': 'Learn the best practices to ensure a healthy and happy pregnancy journey.',
      'likes': 1250,
      'imageUrl': 'https://via.placeholder.com/150',
    },
    {
      'title': 'Nutrition Guide for New Moms',
      'summary': 'A complete guide to eating well during and after pregnancy.',
      'likes': 980,
      'imageUrl': 'https://via.placeholder.com/150',
    },
    {
      'title': 'Preparing for Your Baby’s Arrival',
      'summary': 'Essential checklist to get ready for your newborn.',
      'likes': 750,
      'imageUrl': 'https://via.placeholder.com/150',
    },
    {
      'title': 'Postpartum Recovery Tips',
      'summary': 'How to take care of yourself after giving birth.',
      'likes': 620,
      'imageUrl': 'https://via.placeholder.com/150',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions using MediaQuery for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final fontScaleFactor = screenWidth / 400; // Base font scaling (400px as reference)

    return Scaffold(
      backgroundColor: const Color(0xFFF9ECEF), // Light pink background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9ECEF),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Favorites',
          style: TextStyle(
            fontSize: 24 * fontScaleFactor.clamp(0.9, 1.1),
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Color(0xFFFF6F91), Color(0xFF8B5CF6)],
              ).createShader(
                Rect.fromLTWH(0, 0, 200 * fontScaleFactor, 70),
              ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_sharp, color: Color(0xFFFF6F91)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatAIScreen()),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1), // Favorites tab
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatAIScreen()),
          );
        },
        backgroundColor: const Color(0xFFFF6F91),
        child: const Icon(Icons.chat_bubble, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04, // 4% of screen width
            vertical: screenHeight * 0.02, // 2% of screen height
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Favorite Blogs',
                style: TextStyle(
                  fontSize: 20 * fontScaleFactor.clamp(0.9, 1.1),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              ...favoriteBlogs.map((blog) => _buildBlogCard(
                    context: context,
                    title: blog['title'],
                    summary: blog['summary'],
                    likes: blog['likes'],
                    imageUrl: blog['imageUrl'],
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening "${blog['title']}"...')),
                      );
                    },
                    fontScaleFactor: fontScaleFactor,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlogCard({
    required BuildContext context,
    required String title,
    required String summary,
    required int likes,
    required String imageUrl,
    required VoidCallback onTap,
    required double fontScaleFactor,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: EdgeInsets.only(bottom: 15 * fontScaleFactor.clamp(0.9, 1.1)),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: EdgeInsets.all(16.0 * fontScaleFactor.clamp(0.9, 1.1)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  width: 80 * fontScaleFactor.clamp(0.9, 1.1),
                  height: 80 * fontScaleFactor.clamp(0.9, 1.1),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80 * fontScaleFactor.clamp(0.9, 1.1),
                      height: 80 * fontScaleFactor.clamp(0.9, 1.1),
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 16 * fontScaleFactor.clamp(0.9, 1.1)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 8 * fontScaleFactor.clamp(0.9, 1.1)),
                    Text(
                      summary,
                      style: TextStyle(
                        fontSize: 14 * fontScaleFactor.clamp(0.9, 1.1),
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 10 * fontScaleFactor.clamp(0.9, 1.1)),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Color(0xFFFF6F91),
                          size: 18,
                        ),
                        SizedBox(width: 5 * fontScaleFactor.clamp(0.9, 1.1)),
                        Text(
                          '$likes Likes',
                          style: TextStyle(
                            fontSize: 14 * fontScaleFactor.clamp(0.9, 1.1),
                            color: Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}