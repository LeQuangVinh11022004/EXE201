import 'package:exe_201/chat/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../chat/chatdoctors.dart';
import '/profile/edit_profile_screen.dart';
import '/profile/logout_dialog.dart';
import '/journal/journal_provider.dart';
import 'package:exe_201/payment/card_manager_page.dart';
import 'package:exe_201/profile/pin_history_screen.dart';
import 'package:exe_201/nav/journal_page.dart';
import '/api/account_api.dart';
import 'bottom_nav_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = 'Liza Trass';
  String dob = '01.01.2022';
  String phone = '+1234567889';
  String sex = 'Female';
  String? avatarUrl = 'https://via.placeholder.com/150'; // Thêm biến avatarUrl với giá trị mặc định
  bool isLoading = true;
  final FlutterSecureStorage storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        throw Exception('No access token found. Please log in.');
      }

      final response = await AccountApi.getCurrentUser(accessToken);
      if (response['statusCode'] == 200) {
        final userData = response['body'];
        setState(() {
          name = userData['fullName'] ?? name;
          dob = userData['dateOfBirth']?.split('T')[0] ?? dob;
          phone = userData['phoneNumber'] ?? phone;
          sex = userData['sex'] ?? sex;
          avatarUrl = userData['avatar'] ?? avatarUrl; // Cập nhật avatarUrl từ API
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load user data: ${response['body']}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.pink[50],
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Profile',
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                                  ? NetworkImage(avatarUrl!) // Hiển thị avatar từ URL
                                  : const NetworkImage('https://via.placeholder.com/150'), // Ảnh mặc định
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                                      const SizedBox(width: 5),
                                      Text(
                                        dob,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16, color: Colors.blue),
                                      const SizedBox(width: 5),
                                      Text(
                                        sex,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 16, color: Colors.blue),
                                      const SizedBox(width: 5),
                                      Text(
                                        phone,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final updatedData = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(
                                      name: name,
                                      dob: dob,
                                      phone: phone,
                                      sex: sex,
                                    ),
                                  ),
                                );
                                if (updatedData != null) {
                                  setState(() {
                                    name = updatedData['name'];
                                    dob = updatedData['dob'];
                                    sex = updatedData['sex'] ?? sex;
                                    avatarUrl = updatedData['avatarUrl']; // Cập nhật avatarUrl từ EditProfileScreen
                                  });
                                  await _fetchUserData(); // Đồng bộ dữ liệu mới nhất từ server
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildProfileCard(
                      context: context,
                      icon: Icons.calendar_today,
                      title: 'Pin History',
                      subtitle: 'View your pinned journal entries',
                      onTap: () async {
                        final newEntry = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PinHistory(),
                          ),
                        );
                        if (newEntry != null && newEntry is JournalEntryModel) {
                          Provider.of<JournalProvider>(context, listen: false)
                              .pinEntry(DateTime.now(), newEntry);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Journal entry pinned!')),
                          );
                        }
                      },
                      hasReadButton: true,
                    ),
                    const SizedBox(height: 15),
                    _buildProfileCard(
                      context: context,
                      icon: Icons.credit_card,
                      title: 'Manage Card',
                      subtitle: 'View and manage your card details',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CardManagerPage(),
                          ),
                        );
                      },
                      hasReadButton: true,
                    ),
                    const SizedBox(height: 15),
                    _buildProfileCard(
                      context: context,
                      icon: Icons.settings,
                      title: 'Log Out',
                      onTap: () {
                        LogoutDialog.show(context);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavBar(currentIndex: 4),
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
    );
  }

  Widget _buildProfileCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool hasReadButton = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.blue,
                size: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasReadButton)
                TextButton(
                  onPressed: onTap,
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blue,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}