import 'package:exe_201/nav/journal_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '/api/journal_api.dart';

class CreateJournalScreen extends StatefulWidget {
  const CreateJournalScreen({super.key});

  @override
  _CreateJournalScreenState createState() => _CreateJournalScreenState();
}

class _CreateJournalScreenState extends State<CreateJournalScreen> {
  final _headController = TextEditingController();
  final _contentController = TextEditingController();
  final _headFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _headController.dispose();
    _contentController.dispose();
    _headFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (permission == Permission.photos && Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      var sdkInt = androidInfo.version.sdkInt;
      if (sdkInt < 33) {
        permission = Permission.storage;
      }
    }

    final status = await permission.status;
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Quyền truy cập bị từ chối vĩnh viễn. Vui lòng bật trong cài đặt ứng dụng.'),
          action: SnackBarAction(
            label: 'Cài đặt',
            onPressed: () async {
              await openAppSettings();
            },
          ),
        ),
      );
      return false;
    } else {
      final result = await permission.request();
      if (result.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Quyền truy cập bị từ chối vĩnh viễn. Vui lòng bật trong cài đặt ứng dụng.'),
            action: SnackBarAction(
              label: 'Cài đặt',
              onPressed: () async {
                await openAppSettings();
              },
            ),
          ),
        );
        return false;
      }
      return result.isGranted;
    }
  }

  Future<void> _pickImage() async {
    try {
      bool hasPermission = await _requestPermission(Permission.photos);
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quyền truy cập thư viện ảnh bị từ chối')),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      bool hasPermission = await _requestPermission(Permission.camera);
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quyền truy cập máy ảnh bị từ chối')),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chụp ảnh: $e')),
      );
    }
  }

  Future<void> _createJournalEntry() async {
    setState(() {
      _isLoading = true;
    });

    final head = _headController.text.trim().replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'[\n\r]'), '');
    final content = _contentController.text.trim().replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'[\n\r]'), '');

    if (head.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiêu đề là bắt buộc')),
      );
      return;
    }

    final validContent = content.isNotEmpty ? content : 'Nội dung mặc định';

    try {
      final result = await JournalApi.createJournalEntry(
        head: head,
        content: validContent,
        imagePath: _selectedImage?.path,
      );

      final createdEntry = JournalEntryModel(
        journalId: result['body']['id']?.toString(),
        date: DateTime.now().toIso8601String(),
        head: head,
        content: validContent,
        image: _selectedImage?.path,
      );

      Navigator.pop(context, createdEntry);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo nhật ký thành công!'), duration: Duration(seconds: 2)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tạo nhật ký: $e'), duration: const Duration(seconds: 2)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Tạo Nhật Ký'),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final padding = screenWidth * 0.04; // Dynamic padding (4% of screen width)
            final imageHeight = screenHeight * (isLandscape ? 0.4 : 0.3); // Smaller in landscape
            final buttonWidth = screenWidth > 600 ? screenWidth * 0.4 : screenWidth * 0.45;

            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _headController,
                    focusNode: _headFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề *',
                      hintText: 'Nhập tiêu đề (bắt buộc)',
                      errorText: _headController.text.isEmpty && _isLoading ? 'Vui lòng nhập tiêu đề' : null,
                    ),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _contentFocusNode.requestFocus(),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: screenWidth * 0.04),
                  ),
                  SizedBox(height: padding),
                  TextField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung',
                      hintText: 'Nhập nội dung nhật ký',
                    ),
                    maxLines: isLandscape ? 3 : 5,
                    textInputAction: TextInputAction.done,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: screenWidth * 0.04),
                  ),
                  SizedBox(height: padding * 1.5),
                  _selectedImage != null
                      ? Column(
                          children: [
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: imageHeight.clamp(150, 250),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                  ),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                          size: 50,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: padding),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                              child: const Text('Xóa ảnh'),
                            ),
                          ],
                        )
                      : Text(
                          'Chưa chọn ảnh.',
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: screenWidth * 0.04),
                        ),
                  SizedBox(height: padding),
                  isLandscape
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _pickImage,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Chọn ảnh'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(buttonWidth, 48),
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
                              ),
                            ),
                            SizedBox(width: padding),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _takePhoto,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Chụp ảnh'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(buttonWidth, 48),
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _pickImage,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Chọn ảnh'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 48),
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
                              ),
                            ),
                            SizedBox(height: padding),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _takePhoto,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Chụp ảnh'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 48),
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                  SizedBox(height: padding * 1.5),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createJournalEntry,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                            )
                          : const Text('Tạo'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}