import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../api/blog_api.dart';

class BlogDetailScreen extends StatefulWidget {
  final Map<String, dynamic> blog;

  const BlogDetailScreen({super.key, required this.blog});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  bool _isLoading = false;
  bool _isTogglingLike = false; // Debounce flag for like/unlike
  bool _hasFetchedDetails = false; // Flag to track API fetch completion
  final _commentController = TextEditingController();
  late Map<String, dynamic> _blog;
  bool _isLiked = false;
  bool _isCommentButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _blog = Map<String, dynamic>.from(widget.blog);
    // Sanitize initial image field
    if (_blog['image'] == 'string' || _blog['image']?.toString().isEmpty == true) {
      _blog['image'] = null;
    }
    print('Initial widget.blog: ${widget.blog}');
    print('Initial widget.blog image: ${widget.blog['image']}');
    _blog['comments'] = _blog['comments'] ?? [];
    _commentController.addListener(_updateCommentButtonState);
    _fetchBlogDetails();
    _checkIfUserLiked();
  }

  @override
  void dispose() {
    _commentController.removeListener(_updateCommentButtonState);
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchBlogDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        _showSnackBar('Please sign in to view blog details.');
        return;
      }

      if (_blog['id'] == null) {
        _showSnackBar('Invalid blog ID.');
        return;
      }

      final result = await BlogApi.getBlogById(
        id: _blog['id'].toString(),
        accessToken: accessToken,
      );

      if (result['statusCode'] == 200) {
        setState(() {
          _blog = result['body'] as Map<String, dynamic>;
          // Sanitize image field from API
          if (_blog['image'] == 'string' || _blog['image']?.toString().isEmpty == true) {
            _blog['image'] = null;
          }
          _blog['comments'] = _blog['comments'] ?? [];
          _hasFetchedDetails = true;
        });
      } else {
        throw Exception('Failed to load blog details: ${result['body']}');
      }
    } catch (e) {
      _showSnackBar('Error loading blog details: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _hasFetchedDetails = true;
      });
    }
  }

  void _updateCommentButtonState() {
    setState(() {
      _isCommentButtonEnabled = _commentController.text.trim().isNotEmpty;
    });
  }

  Future<void> _checkIfUserLiked() async {
    setState(() {
      _isLoading = true;
    });

    try {
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      final userId = await storage.read(key: 'user_id');
      if (accessToken == null || userId == null) {
        setState(() {
          _isLiked = false;
        });
        _showSnackBar('Please sign in to view like status.');
        return;
      }

      if (_blog['id'] == null) {
        _showSnackBar('Invalid blog ID.');
        return;
      }

      final result = await BlogApi.getLikedBlogs(
        userId: userId,
        accessToken: accessToken,
      );

      if (result['statusCode'] == 200) {
        final likedBlogIds = (result['body'] as List)
            .map((item) => item['id']?.toString() ?? '')
            .toList();
        setState(() {
          _isLiked = likedBlogIds.contains(_blog['id']?.toString());
        });
      } else {
        throw Exception('Failed to check like status: ${result['body']}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_isTogglingLike) return;

    setState(() {
      _isTogglingLike = true;
      _isLoading = true;
    });

    try {
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        _showSnackBar('Sign in to like!');
        return;
      }

      if (_blog['id'] == null) {
        _showSnackBar('Invalid blog ID.');
        return;
      }

      final result = _isLiked
          ? await BlogApi.deleteLike(
        blogId: _blog['id'],
        accessToken: accessToken,
      )
          : await BlogApi.likeBlog(
        blogId: _blog['id'],
        accessToken: accessToken,
      );

      if (_isLiked && (result['statusCode'] == 200 || result['statusCode'] == 204)) {
        setState(() {
          _blog['likeCount'] = (_blog['likeCount'] ?? 1) - 1;
          _isLiked = false;
        });
        await _fetchBlogDetails(); // Refresh blog details
        await _checkIfUserLiked(); // Refresh like status
        _showSnackBar('Unlike successful!');
      } else if (!_isLiked &&
          (result['statusCode'] == 200 || result['statusCode'] == 201)) {
        setState(() {
          _blog['likeCount'] = (_blog['likeCount'] ?? 0) + 1;
          _isLiked = true;
        });
        await _fetchBlogDetails(); // Refresh blog details
        _showSnackBar('Liked!');
      } else if (!_isLiked &&
          (result['statusCode'] == 400 || result['statusCode'] == 409)) {
        await _fetchBlogDetails(); // Refresh blog details
        await _checkIfUserLiked(); // Refresh like status
        _showSnackBar('Blog already liked, refreshing status.');
      } else {
        final errorMessage = result['body'] is String && result['body'].isNotEmpty
            ? result['body']
            : 'Unknown error';
        _showSnackBar('Failed: $errorMessage');
      }
    } catch (e) {
      _showSnackBar('Error toggling like: $e');
    } finally {
      setState(() {
        _isTogglingLike = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _commentBlog() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      _showSnackBar('Please enter a comment');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      final userId = await storage.read(key: 'user_id');
      if (accessToken == null || userId == null) {
        _showSnackBar('Sign in to comment!');
        return;
      }

      if (_blog['id'] == null) {
        _showSnackBar('Invalid blog ID.');
        return;
      }

      final result = await BlogApi.commentBlog(
        blogId: _blog['id'],
        accessToken: accessToken,
        content: commentText,
        userId: userId,
      );

      if (result['statusCode'] == 200 || result['statusCode'] == 201) {
        await _fetchBlogDetails(); // Refresh blog details
        setState(() {
          _commentController.clear();
        });
        _showSnackBar('Commented!');
      } else {
        final errorMessage = result['body'] is String && result['body'].isNotEmpty
            ? result['body']
            : 'Unknown error';
        _showSnackBar('Failed to comment: $errorMessage');
      }
    } catch (e) {
      _showSnackBar('Error commenting: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    print('Showing SnackBar: $message'); // Debug log
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.fixed,
        backgroundColor: const Color(0xFFF8BBD0), // Sử dụng màu từ theme
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3), // Tự động ẩn sau 3 giây
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr).toLocal();
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blog Detail',
          style: theme.textTheme.headlineMedium,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context,
                _isLiked || _blog['commentCount'] > (widget.blog['commentCount'] ?? 0));
          },
        ),
      ),
      body: _isLoading || !_hasFetchedDetails
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _blog['image'] != null &&
                  _blog['image'].toString().isNotEmpty &&
                  _blog['image'].toString() != 'string' &&
                  Uri.tryParse(_blog['image'].toString())?.isAbsolute ==
                      true &&
                  (_blog['image'].toString().startsWith('http') ||
                      _blog['image'].toString().startsWith('https'))
                  ? Image.network(
                _blog['image'].toString(),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print(
                      'Image load error: $error, URL: ${_blog['image']}');
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: Colors.grey[500],
                      ),
                    ),
                  );
                },
              )
                  : Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _blog['content']?.toString() ?? '',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Posted: ${_formatDateTime(_blog['createdTime'])}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.favorite,
                        size: 28,
                        color: _isLiked ? Colors.redAccent : Colors.grey[700],
                      ),
                      onPressed: _isLoading || _isTogglingLike ? null : _toggleLike,
                    ),
                    Text(
                      '${_blog['likeCount'] ?? 0}',
                      style: theme.textTheme.labelLarge?.copyWith(fontSize: 16),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.comment,
                      size: 28,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_blog['commentCount'] ?? 0}',
                      style: theme.textTheme.labelLarge?.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Comments',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_blog['comments'] != null &&
                (_blog['comments'] as List).isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: (_blog['comments'] as List).length,
                itemBuilder: (context, index) {
                  final comment = (_blog['comments'] as List)[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.grey[300],
                                  child: Icon(
                                    Icons.person,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  comment['username']?.toString() ?? 'Anonymous',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              comment['content']?.toString() ?? '',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Commented: ${_formatDateTime(comment['createdTime'])}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              Text(
                'No comments yet.',
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Write a comment...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                _isLoading || !_isCommentButtonEnabled ? null : _commentBlog,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Comment'),
              ),
            ),
            const SizedBox(height: 16), // Đảm bảo khoảng cách dưới cùng
          ],
        ),
      ),
    );
  }
}