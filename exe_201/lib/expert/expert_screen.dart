import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/account_api.dart'; // Adjust path as needed
// Adjust path as needed
import 'calendar_screen.dart'; // Import the existing CalendarScreen
import 'profile_expert.dart'; // Import the new ProfilePage
import 'doctor_appointments_page.dart'; // Import the chat appointments page

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
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments({String? status}) async {
    setState(() => isLoading = true);
    try {
      final result = await AccountApi.getAppointmentsPagination(
        accessToken: widget.accessToken,
        expertId: widget.expertId,
        appointmentStarusEnum: status != null ? [status] : ['Pending'],
        pageIndex: 1,
        pageSize: 10,
        isDescending: null,
      );
      if (mounted) {
        setState(() {
          if (result['statusCode'] == 200) {
            final body = result['body'];
            if (body is Map<String, dynamic> && body['items'] != null) {
              final items = body['items'];
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
          SnackBar(
            content: Text('Error fetching appointments: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _generateMeetingLink() async {
    try {
      final response = await AccountApi.getMeetingLink(
        accessToken: widget.accessToken,
      );
      if (response['statusCode'] == 200) {
        final body = response['body'];
        if (body is Map<String, dynamic>) {
          return {
            'topic': body['topic'] ?? 'Meeting',
            'meetingUrl': body['meetingUrl'] ?? '',
          };
        }
      }
      throw Exception('Failed to generate meeting link');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating meeting link: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return null;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAppointmentDetails(BuildContext context, Map<String, dynamic> appointment) {
    final dateString = appointment['appointmentDate'] as String? ?? '';
    DateTime? date;
    try {
      date = dateString.isNotEmpty ? DateTime.parse(dateString).toLocal() : null;
    } catch (e) {
      date = null;
    }
    final timeSlot = appointment['timeSlot'] as String? ?? 'No time available';
    final status = appointment['status'] as String? ?? 'Unknown';
    final content = appointment['content'] as String? ?? 'No content';
    final type = appointment['type'] as String? ?? 'Unknown';
    final place = appointment['place'] as String? ?? 'No place specified';
    final linkMeet = appointment['linkMeet'] as String?;
    final feedback = appointment['feedback'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointment Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(Icons.calendar_today, 'Date',
                    date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Invalid date'),
                _buildDetailRow(Icons.access_time, 'Time', timeSlot),
                _buildDetailRow(Icons.info, 'Status', status, color: _getStatusColor(status)),
                _buildDetailRow(Icons.description, 'Content', content),
                _buildDetailRow(Icons.meeting_room, 'Type', type),
                _buildDetailRow(Icons.location_on, 'Place', place),
                if (linkMeet != null && linkMeet.isNotEmpty)
                  _buildDetailRow(Icons.link, 'Meeting Link', linkMeet),
                if (feedback != null) ...[
                  _buildDetailRow(Icons.comment, 'Feedback', feedback['content'] ?? 'No feedback'),
                  _buildDetailRow(Icons.star, 'Rating', '${feedback['stars'] ?? 'No rating'} stars'),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (linkMeet != null && linkMeet.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final Uri url = Uri.parse(linkMeet);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not launch $linkMeet'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.video_call, size: 20),
                        label: Text('Join Meeting'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
                        style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentPage() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: selectedStatus,
            hint: Text(
              'Filter by Status',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            items: <String>['Canceled', 'Completed', 'Pending', 'Approved']
                .map<DropdownMenuItem<String>>((String? value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value ?? 'All'),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedStatus = newValue;
              });
              _fetchAppointments(status: newValue);
            },
            style: TextStyle(color: Colors.black87, fontSize: 16),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade200),
              ),
              filled: true,
              fillColor: Colors.blue.shade50,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            isExpanded: true,
          ),
        ),
        Expanded(
          child: isLoading
              ? Center(
            child: CircularProgressIndicator(
              color: Colors.blue.shade600,
            ),
          )
              : appointmentData == null || appointmentData!.isEmpty
              ? Center(
            child: Text(
              'No appointments found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
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
              final content = appointment['content'] as String? ?? 'No content';
              final id = appointment['id'] as String? ?? '';

              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showAppointmentDetails(context, appointment),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.blue.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Invalid date',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              content,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeSlot,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              'Status: $status',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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
                              if (newStatus == 'Completed') {
                                final meetingLinkData = await _generateMeetingLink();
                                if (meetingLinkData != null) {
                                  final meetingUrl = meetingLinkData['meetingUrl'] as String;
                                  if (meetingUrl.isNotEmpty) {
                                    await AccountApi.updateAppointmentMeetingLink(
                                      accessToken: widget.accessToken,
                                      id: id,
                                      linkMeet: meetingUrl,
                                    );
                                    setState(() {
                                      appointmentData![index]['linkMeet'] = meetingUrl;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Meeting link generated: $meetingUrl'),
                                        backgroundColor: Colors.blue.shade600,
                                      ),
                                    );
                                  }
                                }
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Appointment updated to $newStatus'),
                                  backgroundColor: Colors.blue.shade600,
                                ),
                              );
                              _fetchAppointments(status: selectedStatus);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'Canceled',
                              child: Text('Canceled'),
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
                          icon: Icon(Icons.more_vert, color: Colors.blue.shade600),
                        ),
                      ),
                    ),
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
        return Colors.orange.shade600;
      case 'Canceled':
        return Colors.red.shade600;
      case 'Approved':
        return Colors.green.shade600;
      case 'Completed':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildAppointmentPage(),
      CalendarScreen(accessToken: widget.accessToken, expertId: widget.expertId),
      DoctorAppointmentsPage(), // Add Chat page
      const ProfilePage(),

    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Expert Dashboard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat), // Chat icon
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade600,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        onTap: _onItemTapped,
      ),
    );
  }
}