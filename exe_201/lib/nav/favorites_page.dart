import 'dart:convert';
import 'package:exe_201/chat/chat_page.dart';
import 'package:exe_201/chat/chatdoctors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../blog/blog_detail_screen.dart';
import './bottom_nav_bar.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<dynamic> topBlogs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTopBlogs();
  }

  Future<void> fetchTopBlogs() async {
    final url = Uri.parse(
      'https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net/api/blog?pageIndex=1&pageSize=20&isDescending=false',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final blogs = data['items'];

        final active = blogs
            .where((b) => b['status'] == 'Active')
            .toList();

        active.sort((dynamic a, dynamic b) {
          final int likeA = a['likeCount'] ?? 0;
          final int likeB = b['likeCount'] ?? 0;
          return likeB.compareTo(likeA); // Descending
        });


        setState(() {
          topBlogs = active.take(5).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load blogs');
      }
    } catch (e) {
      print('Error fetching blogs: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final fontScaleFactor = screenWidth / 400;

    return Scaffold(
      backgroundColor: const Color(0xFFF9ECEF),
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
              ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_sharp, color: Color(0xFFFF6F91)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppointmentsPage()),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppointmentsPage()),
          );
        },
        backgroundColor: const Color(0xFFFF6F91),
        child: const Icon(Icons.chat_bubble, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top 5 Most Liked Blogs',
                style: TextStyle(
                  fontSize: 20 * fontScaleFactor.clamp(0.9, 1.1),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              ...topBlogs.map((blog) => _buildBlogCard(
                context: context,
                title: blog['content'] ?? 'No title',
                summary:
                'Likes: ${blog['likeCount']} · Comments: ${blog['commentCount']}',
                likes: blog['likeCount'] ?? 0,
                imageUrl: blog['image']?.isNotEmpty == true
                    ? blog['image']
                    : 'https://via.placeholder.com/150',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlogDetailScreen(blog: blog),
                    ),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
