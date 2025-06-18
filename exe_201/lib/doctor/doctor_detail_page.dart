import 'package:flutter/material.dart';
import '/nav/bottom_nav_bar.dart';
import 'connect_doctor.dart';
import '../api/appointment_api.dart';
import '../api/doctor_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/account_api.dart';
import 'appointment_detail_screen.dart'; // Thêm import này

class DoctorDetailPage extends StatefulWidget {
  final String expertId;

  const DoctorDetailPage({
    super.key,
    required this.expertId,
  });

  @override
  State<DoctorDetailPage> createState() => _DoctorDetailPageState();
}

class _DoctorDetailPageState extends State<DoctorDetailPage> {
  Map<String, dynamic>? doctor;
  List<Map<String, dynamic>> appointments = [];
  bool isLoading = true;
  String? errorMessage;
  String? userId;
  final FlutterSecureStorage storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchUserIdAndData();
  }

  Future<void> _fetchUserIdAndData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      final userData = await AccountApi.getCurrentUser(accessToken);
      if (userData['statusCode'] == 200) {
        final body = userData['body'];
        if (body == null || body is! Map) {
          throw Exception('Invalid user data response: Body is null or not a Map');
        }
        if (body['id'] != null) {
          userId = body['id'] as String;
        } else {
          throw Exception('User ID not found in response');
        }
      } else {
        final body = userData['body'];
        final errorMessage = body is Map ? body['message'] : 'Unknown error';
        throw Exception('Failed to fetch user data: $errorMessage');
      }

      final fetchedDoctor = await DoctorApi.fetchDoctorById(widget.expertId);
      setState(() {
        doctor = fetchedDoctor;
      });

      if (userId != null) {
        final fetchedAppointments = await AppointmentApi.fetchAppointmentsByUserId(
          userId: userId!,
          pageIndex: 0,
          pageSize: 10,
        );
        setState(() {
          appointments = fetchedAppointments;
          isLoading = false;
        });
      } else {
        throw Exception('User ID is null');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink[50]!, Colors.white],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchUserIdAndData,
                child: const Text('Retry'),
              ),
            ],
          ),
        )
            : CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Doctor Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.pink[50]!, Colors.white],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.network(
                                doctor?['imagePath'] ?? 'assets/placeholder_doctor.jpg',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.person, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctor?['name'] ?? 'Unknown Doctor',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.cake, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${doctor?['age'] ?? 'N/A'} yrs',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        doctor?['sex'] == 'Male'
                                            ? Icons.male
                                            : doctor?['sex'] == 'Female'
                                            ? Icons.female
                                            : Icons.person,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        doctor?['sex'] ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 16, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text(
                                        'N/A',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ExpansionTile(
                        title: const Text(
                          'Doctor Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        initiallyExpanded: false,
                        collapsedBackgroundColor: Colors.white,
                        backgroundColor: Colors.white,
                        collapsedIconColor: Colors.blue,
                        iconColor: Colors.blue,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              children: [
                                _buildInfoRow('Degree', doctor?['degree'] ?? 'N/A', icon: Icons.school),
                                _buildInfoRow('Workplace', doctor?['workplace'] ?? 'N/A', icon: Icons.location_on),
                                _buildInfoRow('Specialty', doctor?['specialty'] ?? 'N/A', icon: Icons.medical_services),
                                _buildInfoRow('Description', doctor?['description'] ?? 'N/A', icon: Icons.description),
                                _buildInfoRow('Status', doctor?['status'] ?? 'N/A', icon: Icons.info),
                                _buildInfoRow('Sex', doctor?['sex'] ?? 'N/A', icon: Icons.person),
                                _buildInfoRow('Created Time', _formatDateTime(doctor?['createdTime']), icon: Icons.calendar_today),
                                _buildInfoRow('Updated Time', _formatDateTime(doctor?['updatedTime']), icon: Icons.update),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Appointments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...appointments.map((appointment) => _buildAppointmentTile(
                      time: appointment['timeSlot'] ?? 'N/A',
                      date: _formatDateTime(appointment['appointmentDate']) ?? 'N/A',
                      status: appointment['status'] ?? 'N/A',
                      statusColor: _getStatusColor(appointment['status'] ?? 'N/A'),
                      appointmentId: appointment['id'] ?? '',
                    )),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[800]!, Colors.blue[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConnectDoctorScreen(expertId: widget.expertId),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '+ Connect',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final date = DateTime.parse(dateTime).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildAppointmentTile({
    required String time,
    required String date,
    required String status,
    required Color statusColor,
    required String appointmentId,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailScreen(appointmentId: appointmentId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      status == 'Pending' || status == 'Upcoming'
                          ? Icons.schedule
                          : status == 'Completed'
                          ? Icons.check_circle
                          : status == 'Canceled'
                          ? Icons.cancel
                          : Icons.info,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
      case 'Upcoming':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Canceled':
        return Colors.red;
      case 'Approved':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}