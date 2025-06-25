import 'package:flutter/material.dart';
import '../expert/profile_expert.dart' hide ProfilePage;
import './home_page.dart';
import './favorites_page.dart';
import './journal_page.dart';
import './search_page.dart';
import './profile_page.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const FavoritesPage()),
          (route) => false,
        );
        break;
      case 2:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const JournalPage()),
          (route) => false,
        );
        break;
      case 3:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SearchPage()),
          (route) => false,
        );
        break;
      case 4:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions using MediaQuery for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final fontScaleFactor = screenWidth / 400; // Base font scaling (400px as reference)

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFF9ECEF), // Light pink background
      selectedItemColor: const Color(0xFFFF6F91), // Soft pink for selected item
      unselectedItemColor: Colors.grey[600],
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      elevation: 8, // Subtle shadow for elevation
      selectedLabelStyle: TextStyle(
        fontSize: 12 * fontScaleFactor.clamp(0.9, 1.1),
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12 * fontScaleFactor.clamp(0.9, 1.1),
        fontFamily: 'Poppins',
      ),
      items: [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.home,
            size: 24 * fontScaleFactor.clamp(0.9, 1.1),
          ),
          activeIcon: Icon(
            Icons.home,
            size: 24 * fontScaleFactor.clamp(0.9, 1.1),
            color: const Color(0xFFFF6F91),
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.favorite,
            size: 24 * fontScaleFactor.clamp(0.9, 1.1),
          ),
          activeIcon: Icon(
            Icons.favorite,
            size: 24 * fontScaleFactor.clamp(0.9, 1.1),
            color: const Color(0xFFFF6F91),
          ),
          label: 'Favorites',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.book,
            size: 24 * fontScaleFactor.clamp(0.9, 1.1),
          ),
          activeIcon: Icon(
            Icons.book,
            size: 24 * fontScaleFactor.clamp(0.9, 1.1),
            color: const Color(0xFFFF6F91),
          ),
          label: 'Journal',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.search,
            size: 24 * fontScaleFactor.clamp(0.9, 1.1),
          ),
          activeIcon: Icon(
            Icons.search,
            size: 24 * fontScaleFactor.clamp(0.9, 1.1),
            color: const Color(0xFFFF6F91),
          ),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.person,
            size: 24 * fontScaleFactor.clamp(0.9, 1.1),
          ),
          activeIcon: Icon(
            Icons.person,
            size: 24 * fontScaleFactor.clamp(0.9, 1.1),
            color: const Color(0xFFFF6F91),
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}