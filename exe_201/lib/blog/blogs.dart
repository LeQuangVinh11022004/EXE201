import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../api/blog_api.dart';
import 'blog_detail_screen.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  List<Map<String, dynamic>> _blogs = [];
  bool _isLoading = false;
  bool _isCreatingPost = false;
  final _contentController = TextEditingController();
  String? _selectedImagePath;
  int _currentPage = 1;
  int _pageSize = 5; // Hiển thị 5 mục mỗi trang
  int _totalPages = 1;
  List<Map<String, dynamic>> _currentBlogs = []; // Danh sách hiện tại sau phân trang

  @override
  void initState() {
    super.initState();
    BlogApi.initializeAppLinks();
    _fetchBlogs();
  }

  @override
  void dispose() {
    _contentController.dispose();
    BlogApi.disposeClient();
    super.dispose();
  }

  Future<void> _fetchBlogs() async {
    setState(() => _isLoading = true);

    try {
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        _showSnackBar('No access token found. Please log in.');
        return;
      }

      final result = await BlogApi.getBlogs(accessToken: accessToken);
      if (result['statusCode'] == 200) {
        final data = result['body'] as Map<String, dynamic>;
        setState(() {
          _blogs = List<Map<String, dynamic>>.from(data['items'] ?? []);
          _totalPages = (_blogs.length / _pageSize).ceil();
          _updateCurrentBlogs();
        });
      } else {
        _showSnackBar('Failed to load blogs: ${result['body']}');
      }
    } catch (e) {
      _showSnackBar('Error loading blogs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateCurrentBlogs() {
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    setState(() {
      _currentBlogs = _blogs.sublist(
        startIndex,
        endIndex > _blogs.length ? _blogs.length : endIndex,
      );
    });
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
    });
    _updateCurrentBlogs();
  }

  void _showSnackBar(String message) {
    print('Showing SnackBar: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.fixed,
        backgroundColor: const Color(0xFFF8BBD0),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _selectedImagePath = pickedFile.path);
    }
  }

  Future<void> _uploadImageAndCreatePost() async {
    if (_contentController.text.trim().isEmpty) {
      _showSnackBar('Please enter some content');
      return;
    }

    setState(() => _isLoading = true);

    try {
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        _showSnackBar('No access token found. Please log in.');
        return;
      }

      String? imageUrl;
      if (_selectedImagePath != null) {
        try {
          final uploadResult = await BlogApi.uploadImage(
            accessToken: accessToken,
            filePath: _selectedImagePath!,
          );
          if (uploadResult['statusCode'] == 200) {
            imageUrl = uploadResult['body'] as String?;
          } else {
            _showSnackBar('Failed to upload image: ${uploadResult['body']}');
            return;
          }
        } catch (e) {
          _showSnackBar('Upload failed: $e');
          return;
        }
      }

      await _createPost(imageUrl);
    } catch (e) {
      _showSnackBar('Error processing post: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createPost(String? image) async {
    try {
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        _showSnackBar('No access token found. Please log in.');
        return;
      }

      final result = await BlogApi.createPost(
        accessToken: accessToken,
        content: _contentController.text.trim(),
        image: image,
      );

      if (result['statusCode'] == 200 || result['statusCode'] == 201) {
        _showSnackBar('Post created successfully!');
        setState(() {
          _isCreatingPost = false;
          _contentController.clear();
          _selectedImagePath = null;
        });
        _fetchBlogs();
      } else {
        _showSnackBar('Failed to create post: ${result['body']}');
      }
    } catch (e) {
      _showSnackBar('Error creating post: $e');
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr).toLocal();
      return DateFormat('hh:mm a, dd/MM/yyyy').format(dateTime);
    } catch (_) {
      return 'N/A';
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Blogs', style: theme.textTheme.headlineMedium),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _isCreatingPost = true),
        child: const Icon(Icons.add),
      ),
      body: _isLoading && _blogs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchBlogs,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _currentBlogs.length,
                    itemBuilder: (context, index) {
                      final blog = _currentBlogs[index];
                      final imageUrl = blog['image']?.toString();

                      return GestureDetector(
                        onTap: () async {
                          final shouldRefresh = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlogDetailScreen(blog: blog),
                            ),
                          );
                          if (shouldRefresh == true) {
                            _fetchBlogs();
                          }
                        },
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                imageUrl != null && imageUrl.isNotEmpty
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrl,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return _buildImagePlaceholder();
                                    },
                                    errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                                  ),
                                )
                                    : _buildImagePlaceholder(),
                                const SizedBox(height: 10),
                                Text(
                                  blog['content'] ?? '',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Posted at: ${_formatDateTime(blog['createdTime'])}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                                    const SizedBox(width: 5),
                                    Text('${blog['likeCount'] ?? 0}', style: theme.textTheme.labelLarge),
                                    const SizedBox(width: 10),
                                    Icon(Icons.comment, size: 16, color: theme.colorScheme.secondary),
                                    const SizedBox(width: 5),
                                    Text('${blog['commentCount'] ?? 0}', style: theme.textTheme.labelLarge),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_blogs.isNotEmpty && _totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _currentPage > 1
                              ? () {
                            _goToPage(_currentPage - 1);
                          }
                              : null,
                        ),
                        Text(
                          'Page $_currentPage of $_totalPages',
                          style: theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _currentPage < _totalPages
                              ? () {
                            _goToPage(_currentPage + 1);
                          }
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_isCreatingPost)
            Container(
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Create Post', style: theme.textTheme.titleLarge),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _isCreatingPost = false;
                                    _contentController.clear();
                                    _selectedImagePath = null;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _contentController,
                            decoration: InputDecoration(
                              hintText: "What's on your mind?",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            maxLines: 5,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.colorScheme.secondary),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Add to your post', style: theme.textTheme.labelLarge),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.image, color: theme.colorScheme.secondary),
                                      onPressed: () => _pickImage(ImageSource.gallery),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.camera_alt, color: theme.colorScheme.secondary),
                                      onPressed: () => _pickImage(ImageSource.camera),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (_selectedImagePath != null) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_selectedImagePath!),
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _uploadImageAndCreatePost,
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text('Post', style: theme.textTheme.labelLarge?.copyWith(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}