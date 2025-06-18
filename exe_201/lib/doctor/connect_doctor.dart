import 'dart:convert';

import 'package:exe_201/api/account_api.dart';
import 'package:exe_201/doctor/doctor_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/appointment_api.dart';
import 'package:http/http.dart' as http;

class ConnectDoctorScreen extends StatefulWidget {
  final String expertId;

  const ConnectDoctorScreen({super.key, required this.expertId});

  @override
  State<ConnectDoctorScreen> createState() => _ConnectDoctorScreenState();
}

class _ConnectDoctorScreenState extends State<ConnectDoctorScreen> {
  String? _selectedGender;
  String? _selectedTimeSlotId;
  final List<String> _genders = ['Male', 'Female', 'Other'];
  String? _userId;
  bool _isLoading = false;
  List<Map<String, dynamic>> _timeSlots = [];

  // Controllers để lấy dữ liệu từ TextField
  final _mobileNoController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _medicalHistoryController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchTimeSlots();
  }

  Future<void> _fetchUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        throw Exception('No access token found. Please log in.');
      }

      final response = await AccountApi.getCurrentUser(accessToken);
      if (response['statusCode'] == 200) {
        final userData = response['body'];
        setState(() {
          _userId = userData['id'];
          _fullNameController.text = userData['fullName'] ?? '';
          _ageController.text = _calculateAge(userData['dateOfBirth']?.split('T')[0]) ?? '';
          _mobileNoController.text = userData['phoneNumber'] ?? '';
          _selectedGender = userData['sex'] != null && _genders.contains(userData['sex'])
              ? userData['sex']
              : null;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load user data: ${response['body']}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _calculateAge(String? dob) {
    if (dob == null) return '';
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age.toString();
    } catch (e) {
      return '';
    }
  }

  Future<void> _fetchTimeSlots() async {
    try {
      final timeSlots = await AppointmentApi.fetchTimeSlots();
      setState(() {
        _timeSlots = timeSlots;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching time slots: $e")),
      );
    }
  }
  Future<void> _createAppointment() async {
    if (_userId == null || _selectedTimeSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User ID or Time Slot not selected. Please try again.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final mobileNo = _mobileNoController.text.trim();
    final fullName = _fullNameController.text.trim();
    final age = _ageController.text.trim();
    final address = _addressController.text.trim();
    final medicalHistory = _medicalHistoryController.text.trim();
    final gender = _selectedGender;

    if (mobileNo.isEmpty || fullName.isEmpty || age.isEmpty || gender == null || address.isEmpty || medicalHistory.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields, including Address and Medical History.")),
      );
      return;
    }

    try {
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        throw Exception('No access token found. Please log in.');
      }

      // Gọi API để lấy meeting link
      final client = http.Client();
      final meetLinkResponse = await client.get(
        Uri.parse('https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net/api/helpper/meet-link'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      String meetingUrl = '';
      if (meetLinkResponse.statusCode == 200) {
        final meetLinkData = json.decode(meetLinkResponse.body);
        meetingUrl = meetLinkData['meetingUrl'] as String? ?? '';
        if (meetingUrl.isEmpty) {
          throw Exception('Meeting URL is empty or not found.');
        }
      } else {
        throw Exception('Failed to fetch meeting link: ${meetLinkResponse.statusCode} - ${meetLinkResponse.body}');
      }

      // Tạo request body với meetingUrl
      final appointmentData = {
        "content": medicalHistory,
        "type": "InPerson",
        "appointmentDate": DateTime.now().toUtc().toIso8601String(),
        "place": address,
        "linkMeet": meetingUrl, // Gán meetingUrl vào linkMeet
        "timeSlotId": _selectedTimeSlotId,
        "customerId": _userId,
        "expertId": widget.expertId,
        "mobileNo": mobileNo,
      };

      // Gọi API tạo appointment
      final response = await AppointmentApi.createAppointment(appointmentData, accessToken);
      final appointmentId = response['id'];
      if (appointmentId == null) {
        throw Exception('Appointment ID not found in response.');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment created successfully!")),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DoctorDetailPage(expertId: widget.expertId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating appointment: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mobileNoController.dispose();
    _fullNameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFC1CC), Color(0xFFF5F5F5)], // Soft pink to creamy white
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR INFORMATION',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Enter Mobile No',
                          icon: Icons.phone_outlined,
                          controller: _mobileNoController,
                          theme: theme,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          controller: _fullNameController,
                          theme: theme,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Age',
                                icon: Icons.calendar_today_outlined,
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdownField(
                                label: 'Gender',
                                value: _selectedGender,
                                items: _genders,
                                onChanged: (value) => setState(() => _selectedGender = value),
                                theme: theme,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Address',
                          icon: Icons.location_on_outlined,
                          controller: _addressController,
                          theme: theme,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Medical History',
                          icon: Icons.medical_services_outlined,
                          maxLines: 3,
                          controller: _medicalHistoryController,
                          theme: theme,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownFieldTimeSlot(
                          label: 'Select Time Slot',
                          value: _selectedTimeSlotId,
                          items: _timeSlots.map((slot) => slot['id'] as String).toList(),
                          onChanged: (value) => setState(() => _selectedTimeSlotId = value),
                          theme: theme,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildAnimatedButton(
                              label: 'Back',
                              isPrimary: false,
                              onPressed: () => Navigator.pop(context),
                              theme: theme,
                            ),
                            _buildAnimatedButton(
                              label: 'Next',
                              isPrimary: true,
                              onPressed: _isLoading || _selectedTimeSlotId == null ? null : _createAppointment,
                              isLoading: _isLoading,
                              theme: theme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme!.color, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Text(
            'Connect Doctor',
            style: theme.appBarTheme.titleTextStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextEditingController? controller,
    TextInputType? keyboardType,
    required ThemeData theme,
  }) {
    return Card(
      elevation: theme.cardTheme.elevation!,
      shape: theme.cardTheme.shape,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: theme.inputDecorationTheme.prefixIconColor),
          border: theme.inputDecorationTheme.border,
          labelStyle: theme.inputDecorationTheme.labelStyle,
          filled: theme.inputDecorationTheme.filled,
          fillColor: theme.inputDecorationTheme.fillColor,
          focusedBorder: theme.inputDecorationTheme.focusedBorder,
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required ThemeData theme,
  }) {
    return Card(
      elevation: theme.cardTheme.elevation!,
      shape: theme.cardTheme.shape,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.person, color: Colors.grey),
          border: theme.inputDecorationTheme.border,
          labelStyle: theme.inputDecorationTheme.labelStyle,
          filled: theme.inputDecorationTheme.filled,
          fillColor: theme.inputDecorationTheme.fillColor,
          focusedBorder: theme.inputDecorationTheme.focusedBorder,
        ),
        items: items.map((String item) => DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: theme.textTheme.bodyMedium),
        )).toList(),
        onChanged: onChanged,
        hint: Text('Select', style: theme.textTheme.bodyMedium),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildDropdownFieldTimeSlot({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required ThemeData theme,
  }) {
    return Card(
      elevation: theme.cardTheme.elevation!,
      shape: theme.cardTheme.shape,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time, color: Colors.grey),
          border: theme.inputDecorationTheme.border,
          labelStyle: theme.inputDecorationTheme.labelStyle,
          filled: theme.inputDecorationTheme.filled,
          fillColor: theme.inputDecorationTheme.fillColor,
          focusedBorder: theme.inputDecorationTheme.focusedBorder,
        ),
        items: _timeSlots.map((Map<String, dynamic> slot) => DropdownMenuItem<String>(
          value: slot['id'] as String,
          child: Text('${slot['time']}', style: theme.textTheme.bodyMedium),
        )).toList(),
        onChanged: onChanged,
        hint: Text('Select Time Slot', style: theme.textTheme.bodyMedium),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildAnimatedButton({
    required String label,
    required bool isPrimary,
    required VoidCallback? onPressed,
    bool isLoading = false,
    required ThemeData theme,
  }) {
    return AnimatedScale(
      scale: onPressed != null ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 200),
      child: Card(
        elevation: theme.cardTheme.elevation!,
        shape: theme.cardTheme.shape,
        child: SizedBox(
          width: 150,
          height: 50,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isPrimary ? theme.colorScheme.primary : theme.colorScheme.surface,
              foregroundColor: isPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.secondary,
              shape: theme.elevatedButtonTheme.style!.shape?.resolve({}),
              elevation: 0,
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.secondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}