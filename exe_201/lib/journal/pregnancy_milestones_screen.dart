import 'package:flutter/material.dart';
import '/nav/bottom_nav_bar.dart';

class PregnancyMilestonesScreen extends StatelessWidget {
  const PregnancyMilestonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.pink[50],
        elevation: 0,
        title: const Text(
          'Pregnancy Milestones',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Mom&Baby',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pregnancy Milestones and Checklist',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildMilestoneItem(
                context: context,
                icon: Icons.local_hospital,
                text: '8 weeks (First Trimester) Not pregnancy-related medical check-up',
                details: 'Schedule a general health check-up to ensure you are in good health before focusing on pregnancy-specific care.',
              ),
              _buildMilestoneItem(
                context: context,
                icon: Icons.local_hospital,
                text: '13 weeks (First Trimester)',
                details: 'First trimester screening to assess the baby’s development and health.',
              ),
              _buildMilestoneItem(
                context: context,
                icon: Icons.local_hospital,
                text: '20 weeks (Second Trimester) 20-week scan',
                details: 'Anatomy scan to check the baby’s development and identify any potential issues.',
              ),
              _buildMilestoneItem(
                context: context,
                icon: Icons.local_hospital,
                text: '28 weeks (Third Trimester) Baby shower',
                details: 'Celebrate with friends and family as you prepare for the baby’s arrival.',
              ),
              _buildMilestoneItem(
                context: context,
                icon: Icons.local_hospital,
                text: '32 weeks (Third Trimester) Not later than 34 weeks prepare nursery for baby',
                details: 'Set up the baby’s nursery with essential items like a crib, changing table, and clothes.',
              ),
              _buildMilestoneItem(
                context: context,
                icon: Icons.local_hospital,
                text: '36 weeks (Third Trimester) Last ultrasound (if necessary)',
                details: 'Final ultrasound to check the baby’s position and health before birth.',
              ),
              _buildMilestoneItem(
                context: context,
                icon: Icons.local_hospital,
                text: '36 weeks (Third Trimester) Gender reveal party',
                details: 'A fun event to share the baby’s gender with loved ones.',
              ),
              _buildMilestoneItem(
                context: context,
                icon: Icons.local_hospital,
                text: '40 weeks (Full Term) When baby is ready (Can be earlier or later)',
                details: 'Prepare for delivery, which can happen between 37 and 42 weeks.',
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () {
                    try {
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Back to Journal',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required String details,
  }) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(text),
            content: Text(details),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}