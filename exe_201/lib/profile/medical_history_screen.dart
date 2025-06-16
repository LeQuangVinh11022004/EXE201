import 'package:flutter/material.dart';

class MedicalHistoryScreen extends StatelessWidget {
  const MedicalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder data
    final List<Map<String, String>> history = [
      {'date': 'Jan 15, 2023', 'event': 'Routine Checkup'},
      {'date': 'Mar 10, 2023', 'event': 'Ultrasound'},
      {'date': 'Jun 22, 2023', 'event': 'Blood Test'},
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.pink[50],
        elevation: 0,
        title: const Text(
          'Medical History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
        child: history.isEmpty
            ? const Center(child: Text('No medical history available.'))
            : ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        history[index]['event']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        history[index]['date']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 16),
                      onTap: () {
                        // Add logic to view details if needed
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}