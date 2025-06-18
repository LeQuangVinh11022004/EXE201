import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'dart:convert'; // For jsonDecode
import '../api/account_api.dart'; // Adjust path as needed
// Adjust path as needed

class CalendarScreen extends StatefulWidget {
  final String accessToken;
  final String expertId;

  const CalendarScreen({super.key, required this.accessToken, required this.expertId});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<dynamic>? calendarData;
  bool isLoading = true;
  DateTime currentMonth = DateTime.now(); // Initialize with current date
  List<DateTime>? daysInMonth;

  @override
  void initState() {
    super.initState();
    daysInMonth = _getDaysInMonth(currentMonth.year, currentMonth.month);
    _fetchCalendar();
  }

  Future<void> _fetchCalendar() async {
    try {
      final result = await AccountApi.getExpertCalendar(
        accessToken: widget.accessToken,
        expertId: widget.expertId,
        month: currentMonth.month,
        year: currentMonth.year,
      );
      if (mounted) {
        setState(() {
          final body = result['body'];
          if (body is String) {
            if (body.contains('No appointments found')) {
              calendarData = [];
            } else {
              try {
                calendarData = jsonDecode(body) as List<dynamic>? ?? [];
              } catch (e) {
                calendarData = [];
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to parse response: $e')),
                );
              }
            }
          } else {
            calendarData = body as List<dynamic>? ?? [];
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          calendarData = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  List<DateTime> _getDaysInMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final days = <DateTime>[];
    final firstWeekday = (firstDay.weekday - 1) % 7; // Normalize to 0-6, starting with Monday
    // Prepend days from the previous month
    for (int i = 0; i < firstWeekday; i++) {
      days.add(DateTime(year, month, -(firstWeekday - 1 - i)));
    }
    // Add days of the current month
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(year, month, i));
    }
    // Append days from the next month
    final lastWeekday = lastDay.weekday;
    for (int i = 1; i <= (7 - lastWeekday); i++) {
      days.add(DateTime(year, month + 1, i));
    }
    return days;
  }

  void _changeMonth(int delta) {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + delta);
      daysInMonth = _getDaysInMonth(currentMonth.year, currentMonth.month);
      _fetchCalendar();
    });
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = kToolbarHeight;
    final paddingHeight = 32.0; // Total padding (16.0 top + 16.0 bottom)
    final headerHeight = 80.0; // Navigation row + day labels + spacing
    final availableHeight = screenHeight - appBarHeight - paddingHeight - headerHeight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert Calendar'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.arrow_left,
              color: Theme.of(context).colorScheme.secondary,
              size: 28,
            ),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            '${_monthName(currentMonth.month)} ${currentMonth.year}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_right,
              color: Theme.of(context).colorScheme.secondary,
              size: 28,
            ),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          shape: Theme.of(context).cardTheme.shape,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (var day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                        Text(
                          day,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: day == 'Sat' || day == 'Sun'
                                ? Colors.redAccent
                                : Colors.black54,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: availableHeight > 0 ? availableHeight : screenHeight * 0.6,
                    child: isLoading || daysInMonth == null
                        ? const Center(child: CircularProgressIndicator())
                        : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: daysInMonth!.length,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final date = daysInMonth![index];
                        final isCurrentMonth = date.month == currentMonth.month;
                        final appointments = calendarData?.where((app) {
                          final appDate = DateTime.parse(app['appointmentDate']);
                          return appDate.year == date.year &&
                              appDate.month == date.month &&
                              appDate.day == date.day;
                        }).toList();

                        return GestureDetector(
                          onTap: () {
                            if (appointments != null && appointments.isNotEmpty) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    'Appointments on ${DateFormat('dd/MM/yyyy').format(date)}',
                                    style: Theme.of(context).dialogTheme.titleTextStyle,
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: appointments.map((app) {
                                      return ListTile(
                                        title: Text(
                                          app['time'],
                                          style: Theme.of(context).dialogTheme.contentTextStyle,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.all(4.0),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: isCurrentMonth
                                  ? (appointments != null && appointments.isNotEmpty
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                  : Colors.transparent)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCurrentMonth
                                    ? (appointments != null && appointments.isNotEmpty
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.withOpacity(0.5))
                                    : Colors.grey.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  date.day.toString(),
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: isCurrentMonth ? Colors.black87 : Colors.grey,
                                    fontWeight: appointments != null && appointments.isNotEmpty
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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