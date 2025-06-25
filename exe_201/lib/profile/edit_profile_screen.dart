import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '/api/account_api.dart';
import '/api/upload_helper.dart'; // Import UploadHelper

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String dob;
  final String phone;
  final String sex;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.dob,
    required this.phone,
    required this.sex,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  String? _selectedSex;
  String? _avatarUrl;
  File? _avatarImage;
  final FlutterSecureStorage storage = FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();
  String? userId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _dobController = TextEditingController(text: widget.dob);
    _selectedSex = widget.sex;
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await storage.read(key: 'user_id');
    final accessToken = await storage.read(key: 'access_token');

    if (accessToken != null && id != null) {
      try {
        final response = await AccountApi.getCurrentUser(accessToken);
        if (response['statusCode'] == 200) {
          final userData = response['body'];
          setState(() {
            userId = id;
            _nameController.text = userData['fullName'] ?? widget.name;
            _dobController.text = userData['dateOfBirth']?.split('T')[0] ?? widget.dob;
            _selectedSex = userData['sex'] ?? widget.sex;
            _avatarUrl = userData['avatar'];
            isLoading = false;
          });
        } else {
          throw Exception('Failed to load user data: ${response['body']}');
        }
      } catch (e) {
        setState(() {
          userId = id;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        userId = id;
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (await file.exists()) {
          final sizeInBytes = await file.length();
          if (sizeInBytes > 10 * 1024 * 1024) { // Limit to 10MB
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image size exceeds 10MB limit')),
            );
            return;
          }
          setState(() {
            _avatarImage = file; // Update _avatarImage immediately
            _avatarUrl = null; // Clear _avatarUrl to force preview of new image
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid image file')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
      print('Pick image error: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Still loading user data. Please wait.')),
      );
      return;
    }

    String? accessToken;
    try {
      accessToken = await storage.read(key: 'access_token');
      if (accessToken == null || userId == null || _selectedSex == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication or data error. Please log in again.')),
        );
        return;
      }

      String? newAvatarUrl = _avatarUrl;
      if (_avatarImage != null) {
        try {
          newAvatarUrl = await UploadHelper.uploadAvatar(_avatarImage!);
          setState(() {
            _avatarUrl = newAvatarUrl; // Update _avatarUrl after successful upload
            _avatarImage = null; // Clear _avatarImage after upload
          });
        } catch (e) {
          if (e.toString().contains('Session expired')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Session expired. Please log in again.')),
            );
            Navigator.pushReplacementNamed(context, '/login');
            return;
          } else {
            rethrow;
          }
        }
      }

      final dateOfBirth = '${_dobController.text}T00:00:00Z';
      final response = await AccountApi.updateAccount(
        accessToken: accessToken,
        id: userId!,
        fullName: _nameController.text,
        dateOfBirth: dateOfBirth,
        sex: _selectedSex!,
      );

      if (response['statusCode'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        final updatedUserData = await _fetchUpdatedUserData(accessToken);
        if (updatedUserData != null) {
          setState(() {
            _nameController.text = updatedUserData['fullName'] ?? _nameController.text;
            _dobController.text = updatedUserData['dateOfBirth']?.split('T')[0] ?? _dobController.text;
            _selectedSex = updatedUserData['sex'] ?? _selectedSex;
            _avatarUrl = updatedUserData['avatar'] ?? newAvatarUrl;
          });
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pop(context, {
            'name': updatedUserData['fullName'] ?? _nameController.text,
            'dob': updatedUserData['dateOfBirth']?.split('T')[0] ?? _dobController.text,
            'sex': updatedUserData['sex'] ?? _selectedSex,
            'avatarUrl': updatedUserData['avatar'] ?? newAvatarUrl,
          });
        } else {
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pop(context, {
            'name': _nameController.text,
            'dob': _dobController.text,
            'sex': _selectedSex,
            'avatarUrl': newAvatarUrl,
          });
        }
      } else if (response['statusCode'] == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in again.')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${response['body'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<Map<String, dynamic>?> _fetchUpdatedUserData(String accessToken) async {
    try {
      final response = await AccountApi.getCurrentUser(accessToken);
      if (response['statusCode'] == 200) {
        return response['body'];
      } else {
        throw Exception('Failed to fetch updated user data: ${response['body']}');
      }
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.pink[50],
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update Your Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _avatarImage != null
                          ? FileImage(_avatarImage!) // Show picked image preview
                          : _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? NetworkImage(_avatarUrl!) // Show uploaded URL
                          : const NetworkImage('https://via.placeholder.com/150'), // Default placeholder
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.blue),
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _dobController,
                decoration: InputDecoration(
                  labelText: 'Date of Birth (YYYY-MM-DD)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedSex,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSex = value;
                  });
                },
              ),
              const SizedBox(height: 30),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
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
}