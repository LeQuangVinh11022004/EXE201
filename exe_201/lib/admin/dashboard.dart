import 'package:flutter/material.dart';
import '../api/account_api.dart'; // Import your AccountApi class

class CalendarScreen extends StatefulWidget {
  final String accessToken;
  final String expertId;

  const CalendarScreen({super.key, required this.accessToken, required this.expertId});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Map<String, dynamic>? calendarData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCalendar();
  }

  Future<void> _fetchCalendar() async {
    try {
      final result = await AccountApi.getExpertCalendar(
        accessToken: widget.accessToken,
        expertId: widget.expertId,
        month: DateTime.now().month,
        year: DateTime.now().year,
      );
      if (mounted) {
        setState(() {
          calendarData = result['body'];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert Calendar'),
      ),
      body: Theme(
        data: appTheme(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : calendarData == null
              ? const Center(child: Text('No data available'))
              : Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calendar Data',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Status Code: ${calendarData?['statusCode']}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Body: ${calendarData?['body'].toString()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}