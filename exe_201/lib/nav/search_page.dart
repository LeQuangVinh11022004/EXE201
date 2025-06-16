import 'package:exe_201/chat/chatdoctors.dart';
import 'package:exe_201/nav/bottom_nav_bar.dart';
import 'package:exe_201/chat/chatAI_page.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> searchResults = [];
  bool isSearching = false;

  // Mock data for doctors and blogs (in Vietnamese for content)
  final List<Map<String, String>> data = [
    {
      'title': 'Tìm hiểu về bệnh tim mạch',
      'type': 'Blog',
      'specialty': 'Tim mạch',
      'author': 'BS. Nguyễn Văn A',
      'description': 'Bài viết chi tiết về cách phòng ngừa và điều trị bệnh tim mạch.'
    },
    {
      'title': 'BS. Trần Thị B',
      'type': 'Bác sĩ',
      'specialty': 'Nhi khoa',
      'description': 'Chuyên gia về sức khỏe trẻ em với 10 năm kinh nghiệm.'
    },
    {
      'title': 'Chăm sóc da mùa hè',
      'type': 'Blog',
      'specialty': 'Da liễu',
      'author': 'BS. Lê Văn C',
      'description': 'Mẹo giữ da khỏe mạnh trong thời tiết nóng bức.'
    },
    {
      'title': 'BS. Phạm Văn D',
      'type': 'Bác sĩ',
      'specialty': 'Tim mạch',
      'description': 'Chuyên gia phẫu thuật tim với hơn 15 năm kinh nghiệm.'
    },
  ];

  void _search(String query) {
    setState(() {
      isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        searchResults = [];
      } else {
        searchResults = data
            .where((item) =>
                item['title']!.toLowerCase().contains(query.toLowerCase()) ||
                item['specialty']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9ECEF), // Match with ProfilePage background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9ECEF), // Match with ProfilePage AppBar
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Search Doctors & Blogs',
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
            icon: const Icon(
              Icons.chat_sharp,
              color: Color(0xFFFF6F91),
              size: 28, // Match with a prominent size
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatAIScreen()),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
          final padding = screenWidth * 0.04; // Dynamic padding (4% of screen width)
          final avatarSize = screenWidth * 0.12; // Dynamic avatar size

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm bác sĩ, blog, chuyên khoa...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: isSearching
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.primary),
                            onPressed: () {
                              _searchController.clear();
                              _search('');
                            },
                          )
                        : null,
                    contentPadding: EdgeInsets.symmetric(vertical: padding * 0.5, horizontal: padding),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: screenWidth * 0.04),
                  onChanged: _search,
                ),
                SizedBox(height: padding),
                // Search Results
                Expanded(
                  child: searchResults.isEmpty && !isSearching
                      ? Center(
                          child: Text(
                            'Nhập từ khóa để tìm bác sĩ hoặc blog',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: Colors.black54,
                                  fontSize: screenWidth * 0.045,
                                ),
                          ),
                        )
                      : searchResults.isEmpty && isSearching
                          ? Center(
                              child: Text(
                                'Không tìm thấy kết quả',
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      color: Colors.black54,
                                      fontSize: screenWidth * 0.045,
                                    ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                final item = searchResults[index];
                                return Card(
                                  elevation: 4,
                                  margin: EdgeInsets.symmetric(vertical: padding * 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  color: Colors.white,
                                  child: ListTile(
                                    contentPadding: EdgeInsets.all(padding),
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                      radius: avatarSize.clamp(20, 30),
                                      child: Text(
                                        item['type'] == 'Blog' ? '📝' : '👨‍⚕️',
                                        style: TextStyle(fontSize: avatarSize * 0.5),
                                      ),
                                    ),
                                    title: Text(
                                      item['title']!,
                                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.045,
                                          ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: padding * 0.25),
                                        Text(
                                          'Chuyên khoa: ${item['specialty']}',
                                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                                color: Colors.black54,
                                                fontSize: screenWidth * 0.035,
                                              ),
                                        ),
                                        if (item['author'] != null)
                                          Text(
                                            'Tác giả: ${item['author']}',
                                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                                  color: Colors.black54,
                                                  fontSize: screenWidth * 0.035,
                                                ),
                                          ),
                                        SizedBox(height: padding * 0.25),
                                        Text(
                                          item['description']!,
                                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                                color: Colors.black54,
                                                fontSize: screenWidth * 0.035,
                                              ),
                                          maxLines: isLandscape ? 1 : 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Xem chi tiết: ${item['title']}'),
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppointmentsPage()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.chat_bubble, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}