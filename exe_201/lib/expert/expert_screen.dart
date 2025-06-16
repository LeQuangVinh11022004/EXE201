import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../api/account_api.dart'; // Adjust path as needed
import '../theme.dart'; // Adjust path as needed
import 'calendar_screen.dart'; // Import the existing CalendarScreen

class ExpertScreen extends StatefulWidget {
  final String accessToken;
  final String expertId;

  const ExpertScreen({super.key, required this.accessToken, required this.expertId});

  @override
  _ExpertScreenState createState() => _ExpertScreenState();
}

class _ExpertScreenState extends State<ExpertScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>>? appointmentData;
  bool isLoading = true;
  String? selectedStatus; // Thêm biến để theo dõi trạng thái được chọn để lọc

  @override
  void initState() {
    super.initState();
    _fetchAppointments(); // Lấy danh sách ban đầu với status mặc định (Pending)
  }

  Future<void> _fetchAppointments({String? status}) async {
    setState(() => isLoading = true);
    try {
      final result = await AccountApi.getAppointmentsPagination(
        accessToken: widget.accessToken,
        expertId: widget.expertId,
        appointmentStarusEnum: status != null ? [status] : ['Pending'], // Lọc theo trạng thái được chọn
        pageIndex: 1,
        pageSize: 10,
        isDescending: null,
      );
      print('API Result: $result'); // Log toàn bộ kết quả
      if (mounted) {
        setState(() {
          if (result['statusCode'] == 200) {
            final body = result['body'];
            print('API Body: $body'); // Log body
            if (body is Map<String, dynamic> && body['items'] != null) {
              final items = body['items'];
              print('Items: $items, Type: ${items.runtimeType}');
              appointmentData = items is List
                  ? items.map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{}).toList()
                  : [];
            } else {
              appointmentData = [];
            }
          } else {
            appointmentData = [];
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          appointmentData = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching appointments: $e')),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildAppointmentPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButton<String>(
            value: selectedStatus,
            hint: const Text('Filter by Status'),
            items: <String>['Canceled', 'Completed', 'Pending', 'Approved']
                .map<DropdownMenuItem<String>>((String? value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value ?? 'All'),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedStatus = newValue; // Cập nhật trạng thái được chọn
              });
              _fetchAppointments(status: newValue); // Lấy lại danh sách theo trạng thái mới
            },
            style: Theme.of(context).textTheme.bodyMedium,
            underline: const SizedBox(),
            isExpanded: true, // Đảm bảo dropdown chiếm toàn bộ chiều rộng
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : appointmentData == null || appointmentData!.isEmpty
              ? const Center(child: Text('No appointments found'))
              : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: appointmentData!.length,
            itemBuilder: (context, index) {
              final appointment = appointmentData![index];
              final dateString = appointment['appointmentDate'] as String? ?? '';
              DateTime? date;
              try {
                date = dateString.isNotEmpty ? DateTime.parse(dateString).toLocal() : null;
              } catch (e) {
                date = null;
              }
              final timeSlot = appointment['timeSlot'] as String? ?? 'No time available';
              final status = appointment['status'] as String? ?? 'Unknown';
              final id = appointment['id'] as String? ?? '';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12.0),
                  title: Text(
                    date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Invalid date',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeSlot,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Status: $status',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (String newStatus) async {
                      try {
                        await AccountApi.updateAppointmentStatus(
                          accessToken: widget.accessToken,
                          id: id,
                          status: newStatus,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Appointment updated to $newStatus')),
                        );
                        _fetchAppointments(status: selectedStatus); // Làm mới danh sách theo trạng thái hiện tại
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'Canceled',
                        child: Text('Cancel'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Completed',
                        child: Text('Complete'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Pending',
                        child: Text('Pending'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Approved',
                        child: Text('Approve'),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Canceled':
        return Colors.red;
      case 'Approved':
        return Colors.green;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildAppointmentPage(),
      CalendarScreen(accessToken: widget.accessToken, expertId: widget.expertId),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Appointment'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Profile Page',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}