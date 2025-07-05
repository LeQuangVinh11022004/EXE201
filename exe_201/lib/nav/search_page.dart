import 'dart:convert';
import 'package:exe_201/chat/chatdoctors.dart';
import 'package:exe_201/nav/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../blog/blog_detail_screen.dart';
import '../doctor/doctor_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FlutterSecureStorage storage = FlutterSecureStorage();

  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;

  Future<void> _search(String query) async {
    setState(() {
      isSearching = query.isNotEmpty;
      searchResults = [];
    });

    if (query.isEmpty) return;

    final accessToken = await storage.read(key: 'access_token');
    if (accessToken == null) {
      _showSnackBar("Vui lòng đăng nhập để tìm kiếm");
      return;
    }

    try {
      final blogResponse = await _searchBlogs(query, accessToken);
      final expertResponse = await _searchExperts(query, accessToken);

      final blogs = blogResponse['statusCode'] == 200 ? List<Map<String, dynamic>>.from(blogResponse['body']) : [];
      final experts = expertResponse['statusCode'] == 200 ? List<Map<String, dynamic>>.from(expertResponse['body']) : [];

      final merged = [
        ...blogs.map((b) => {
          'type': 'Blog',
          'id': b['id'], // cần thiết
          'title': b['content'] ?? '[Không có nội dung]',
          'description': '',
          'specialty': '',
          'author': '',
          'image': b['image'],
          'likeCount': b['likeCount'] ?? 0,
          'commentCount': b['commentCount'] ?? 0,
        }),
        ...experts.map((e) => {
          'type': 'Expert',
          'id': e['id'], // cần thiết
          'title': e['user']?['fullName'] ?? 'Không rõ',
          'description': e['description'] ?? '',
          'specialty': e['specialty'] ?? '',
          'author': '',
          'avatar': e['user']?['avatar'],
        }),

      ];


      setState(() {
        searchResults = merged;
      });
    } catch (e) {
      _showSnackBar("Lỗi tìm kiếm: $e");
    }
  }

  Future<Map<String, dynamic>> _searchBlogs(String searchString, String accessToken) async {
    final url = Uri.parse('https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net/api/blog?searchString=$searchString&pageIndex=1&pageSize=10');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return {
        'statusCode': 200,
        'body': jsonDecode(response.body)['items'], // assuming paging response
      };
    } else {
      return {
        'statusCode': response.statusCode,
        'body': [],
      };
    }
  }

  Future<Map<String, dynamic>> _searchExperts(String searchString, String accessToken) async {
    final url = Uri.parse('https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net/api/expert?searchString=$searchString&pageIndex=1&pageSize=10');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return {
        'statusCode': 200,
        'body': jsonDecode(response.body)['items'], // assuming paging response
      };
    } else {
      return {
        'statusCode': response.statusCode,
        'body': [],
      };
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
          backgroundColor: Colors.pink[50],
          elevation: 0,
          title: Text(
            'Search',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [Color(0xFFFF6F91), Color(0xFF8B5CF6)],
                ).createShader(
                  Rect.fromLTWH(0, 0, 200, 70),
                ),
            ),
          ),

        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentsPage()));
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: "Tìm kiếm...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: isSearching
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _search('');
                  },
                )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: searchResults.isEmpty
                  ? Center(
                child: Text(
                  isSearching ? "Không tìm thấy kết quả." : "Nhập từ khóa để tìm kiếm.",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
                  : ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final item = searchResults[index];
                  return Card(
                    child: ListTile(
                      leading: item['type'] == 'Expert' && item['avatar'] != null
                          ? CircleAvatar(backgroundImage: NetworkImage(item['avatar']))
                          : CircleAvatar(
                        backgroundColor: Colors.pink[100],
                        child: Text(item['type'] == 'Blog' ? '📝' : '👨‍⚕️'),
                      ),
                      title: Text(item['title'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item['specialty']?.isNotEmpty ?? false)
                            Text("Chuyên khoa: ${item['specialty']}"),
                          if (item['author']?.isNotEmpty ?? false)
                            Text("Tác giả: ${item['author']}"),
                          if (item['description']?.isNotEmpty ?? false)
                            Text(item['description']),
                          if (item['type'] == 'Blog')
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.thumb_up, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('${item['likeCount']}'),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.comment, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('${item['commentCount']}'),
                                ],
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        if (item['type'] == 'Blog') {
                          // Nếu là blog → chuyển sang BlogDetailScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlogDetailScreen(blog: item), // nhớ thêm 'id' vào merged data
                            ),
                          );
                        } else {
                          // Nếu là expert → chuyển sang DoctorDetailScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorDetailPage(expertId: item['id']),
                            ),
                          );
                        }
                      },

                    ),
                  );

                },
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3),
    );
  }
}
