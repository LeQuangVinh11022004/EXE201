import 'package:exe_201/chat/chat_page.dart';
import 'package:exe_201/chat/chatdoctors.dart';
import 'package:exe_201/blog/blogs.dart';
import 'package:exe_201/payment/membership_package_page.dart';
import 'package:exe_201/nav/journal_page.dart';
import 'package:flutter/material.dart';
import '../doctor/doctor_detail_page.dart';
import '/nav/bottom_nav_bar.dart';
import '../api/doctor_api.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> doctors = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await DoctorApi.fetchDoctors(
        pageIndex: 1, // Mặc định pageIndex
        pageSize: 10, // Mặc định pageSize
        status: 'Active', // Mặc định status
      );
      setState(() {
        doctors = List<Map<String, dynamic>>.from(data['doctors']);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
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
          'Mom&Baby',
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
                MaterialPageRoute(builder: (context) => const AppointmentsPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDoctors,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.01,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCategoryButton(
                      context,
                      icon: Icons.person,
                      label: 'Doctors',
                      gradientColors: const [Color(0xFFFFA1B5), Color(0xFFFFD1DC)],
                      onTap: () {},
                      fontScaleFactor: fontScaleFactor,
                    ),
                    _buildCategoryButton(
                      context,
                      icon: Icons.book,
                      label: 'Journal',
                      gradientColors: const [Color(0xFFA1C4FD), Color(0xFFD1E9FF)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const JournalPage()),
                        );
                      },
                      fontScaleFactor: fontScaleFactor,
                    ),
                    _buildCategoryButton(
                      context,
                      icon: Icons.local_hospital,
                      label: 'Blog',
                      gradientColors: const [Color(0xFFA1EFD1), Color(0xFFD1FFF4)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BlogScreen()),
                        );
                      },
                      fontScaleFactor: fontScaleFactor,
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'EXPERIENCED DOCTOR',
                      style: TextStyle(
                        fontSize: 18 * fontScaleFactor.clamp(0.9, 1.1),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 14 * fontScaleFactor.clamp(0.9, 1.1),
                          color: const Color(0xFF8B5CF6),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.015),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (errorMessage != null)
                  Center(
                    child: Column(
                      children: [
                        Text(
                          errorMessage!,
                          style: TextStyle(
                            fontSize: 14 * fontScaleFactor.clamp(0.9, 1.1),
                            color: Colors.redAccent,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _fetchDoctors,
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              fontSize: 14 * fontScaleFactor.clamp(0.9, 1.1),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (doctors.isEmpty)
                  Center(
                    child: Text(
                      'No doctors available',
                      style: TextStyle(
                        fontSize: 14 * fontScaleFactor.clamp(0.9, 1.1),
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  )
                else
                  ...doctors.map((doctor) => Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.01),
                        child: _buildDoctorCard(
                          name: doctor['name'],
                          description: doctor['description'],
                          imagePath: doctor['imagePath'],
                              // Trong _buildDoctorCard của HomePage
                          // Trong _buildDoctorCard của HomePage
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DoctorDetailPage(
                                  expertId: doctor['id'], // Đảm bảo doctor['id'] chính là expertId
                                ),
                              ),
                            );
                          },
                          fontScaleFactor: fontScaleFactor,
                        ),
                      )),
                SizedBox(height: screenHeight * 0.02),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MembershipPackagePage()),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6F91), Color(0xFF8B5CF6)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SIGN UP FOR MEMBERSHIP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
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

  Widget _buildCategoryButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required double fontScaleFactor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100 * fontScaleFactor.clamp(0.9, 1.1),
        padding: EdgeInsets.symmetric(vertical: 16 * fontScaleFactor.clamp(0.9, 1.1)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32 * fontScaleFactor.clamp(0.9, 1.1),
              color: Colors.black87,
            ),
            SizedBox(height: 8 * fontScaleFactor.clamp(0.9, 1.1)),
            Text(
              label,
              style: TextStyle(
                fontSize: 14 * fontScaleFactor.clamp(0.9, 1.1),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard({
    required String name,
    required String description,
    required String imagePath,
    required VoidCallback onTap,
    required double fontScaleFactor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12 * fontScaleFactor.clamp(0.9, 1.1)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imagePath,
                width: 60 * fontScaleFactor.clamp(0.9, 1.1),
                height: 60 * fontScaleFactor.clamp(0.9, 1.1),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/placeholder_doctor.jpg',
                  width: 60 * fontScaleFactor.clamp(0.9, 1.1),
                  height: 60 * fontScaleFactor.clamp(0.9, 1.1),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 12 * fontScaleFactor.clamp(0.9, 1.1)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 4 * fontScaleFactor.clamp(0.9, 1.1)),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14 * fontScaleFactor.clamp(0.9, 1.1),
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16 * fontScaleFactor.clamp(0.9, 1.1),
              color: const Color(0xFFFF6F91),
            ),
          ],
        ),
      ),
    );
  }
}