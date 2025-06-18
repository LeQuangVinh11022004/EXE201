import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/account_api.dart'; // Adjust path as needed
import '../profile/edit_profile_screen.dart';
// Adjust path as needed
import '/profile/logout_dialog.dart';

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
  String? avatarUrl = 'https://via.placeholder.com/150';
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
          avatarUrl = userData['avatar'] ?? avatarUrl;
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
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            foreground: Paint()
              ..shader = LinearGradient(
                colors: [Colors.blue.shade600, Colors.purple.shade400],
              ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
          ),
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Colors.blue.shade600,
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.blue.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                                ? NetworkImage(avatarUrl!)
                                : NetworkImage('https://via.placeholder.com/150'),
                            backgroundColor: Colors.blue.shade100,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildProfileDetail(Icons.calendar_today, dob),
                                _buildProfileDetail(Icons.person, sex),
                                _buildProfileDetail(Icons.phone, phone),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue.shade600),
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
                                  avatarUrl = updatedData['avatarUrl'];
                                });
                                await _fetchUserData();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileCard(
                context: context,
                icon: Icons.logout,
                title: 'Log Out',
                onTap: () {
                  LogoutDialog.show(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetail(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.blue.shade600,
                  size: 30,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blue.shade600,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}