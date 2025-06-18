import 'package:exe_201/nav/journal_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '/api/journal_api.dart';

class UpdateJournalScreen extends StatefulWidget {
  final JournalEntryModel existingEntry;

  const UpdateJournalScreen({super.key, required this.existingEntry});

  @override
  _UpdateJournalScreenState createState() => _UpdateJournalScreenState();
}

class _UpdateJournalScreenState extends State<UpdateJournalScreen> {
  final _headController = TextEditingController();
  final _contentController = TextEditingController();
  final _headFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _headController.text = widget.existingEntry.head;
    _contentController.text = widget.existingEntry.content;
    if (widget.existingEntry.image != null && widget.existingEntry.image!.isNotEmpty) {
      _selectedImage = File(widget.existingEntry.image!);
    }
  }

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

  Future<void> _updateJournalEntry() async {
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
      if (widget.existingEntry.journalId == null || widget.existingEntry.journalId!.isEmpty) {
        throw Exception('ID nhật ký không hợp lệ. Không thể cập nhật.');
      }

      await JournalApi.updateJournalEntry(
        journalId: widget.existingEntry.journalId!,
        head: head,
        content: validContent,
        imagePath: _selectedImage?.path ?? widget.existingEntry.image,
      );

      final updatedEntry = JournalEntryModel(
        journalId: widget.existingEntry.journalId,
        date: widget.existingEntry.date,
        head: head,
        content: validContent,
        image: _selectedImage?.path ?? widget.existingEntry.image,
      );

      Navigator.pop(context, updatedEntry);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật nhật ký thành công!'), duration: Duration(seconds: 2)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật nhật ký: $e'), duration: const Duration(seconds: 2)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Chỉnh Sửa Nhật Ký'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _headController,
                focusNode: _headFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề *',
                  hintText: 'Nhập tiêu đề (bắt buộc)',
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _contentFocusNode.requestFocus(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                focusNode: _contentFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Nội dung',
                  hintText: 'Nhập nội dung nhật ký',
                ),
                maxLines: 5,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              _selectedImage != null
                  ? Column(
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 200,
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
                        const SizedBox(height: 12),
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
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Chọn ảnh'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Chụp ảnh'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateJournalEntry,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                        )
                      : const Text('Cập nhật'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}