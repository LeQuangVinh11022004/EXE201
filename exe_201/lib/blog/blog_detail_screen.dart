import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
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
  final _commentController = TextEditingController();
  late Map<String, dynamic> _blog;
  bool _isLiked = false;
  bool _isCommentButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _blog = Map<String, dynamic>.from(widget.blog);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please sign in to view blog details.'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
            backgroundColor: const Color(0xFFF8BBD0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      if (_blog['id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid blog ID.'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
            backgroundColor: const Color(0xFFF8BBD0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      final result = await BlogApi.getBlogById(
        id: _blog['id'].toString(),
        accessToken: accessToken,
      );

      if (result['statusCode'] == 200) {
        setState(() {
          _blog = result['body'] as Map<String, dynamic>;
          // Ensure comments is a list, even if empty
          _blog['comments'] = _blog['comments'] ?? [];
        });
      } else {
        throw Exception('Failed to load blog details: ${result['body']}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading blog details: $e'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
          backgroundColor: const Color(0xFFF8BBD0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please sign in to view like status.'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
            backgroundColor: const Color(0xFFF8BBD0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      if (_blog['id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid blog ID.'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
            backgroundColor: const Color(0xFFF8BBD0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      final result = await BlogApi.getLikedBlogs(
        userId: userId,
        accessToken: accessToken,
      );

      if (result['statusCode'] == 200) {
        final likedBlogIds = (result['body'] as List).map((item) => item['id']?.toString() ?? '').toList();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sign in to like!'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
            backgroundColor: const Color(0xFFF8BBD0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      if (_blog['id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid blog ID.'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
            backgroundColor: const Color(0xFFF8BBD0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      final result = _isLiked
          ? await BlogApi.deleteLike(blogId: _blog['id'], accessToken: accessToken)
          : await BlogApi.likeBlog(blogId: _blog['id'], accessToken: accessToken);

      if (_isLiked && (result['statusCode'] == 200 || result['statusCode'] == 204)) {
        setState(() {
          _blog['likeCount'] = (_blog['likeCount'] ?? 1) - 1;
          _isLiked = false;
        });
        await _checkIfUserLiked();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unlike successful!'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
            backgroundColor: const Color(0xFFF8BBD0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      } else if (!_isLiked && (result['statusCode'] == 200 || result['statusCode'] == 201)) {
        setState(() {
          _blog['likeCount'] = (_blog['likeCount'] ?? 0) + 1;
          _isLiked = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Liked!'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
            backgroundColor: const Color(0xFFF8BBD0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      } else if (!_isLiked && (result['statusCode'] == 400 || result['statusCode'] == 409)) {
        await _checkIfUserLiked();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Blog already liked, refreshing status.'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
            backgroundColor: const Color(0xFFF8BBD0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        final errorMessage = result['body'] is String && result['body'].isNotEmpty
            ? result['body']
            : 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $errorMessage'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
            backgroundColor: const Color(0xFFF8BBD0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error toggling like: $e'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
          backgroundColor: const Color(0xFFF8BBD0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a comment'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
          backgroundColor: const Color(0xFFF8BBD0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sign in to comment!'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
            backgroundColor: const Color(0xFFF8BBD0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      if (_blog['id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid blog ID.'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
            backgroundColor: const Color(0xFFF8BBD0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      final result = await BlogApi.commentBlog(
        blogId: _blog['id'],
        accessToken: accessToken,
        content: commentText,
        userId: userId,
      );

      if (result['statusCode'] == 200 || result['statusCode'] == 201) {
        // Refetch blog details to sync comments
        await _fetchBlogDetails();
        setState(() {
          _commentController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Commented!'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
            backgroundColor: const Color(0xFFF8BBD0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      } else {
        final errorMessage = result['body'] is String && result['body'].isNotEmpty
            ? result['body']
            : 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to comment: $errorMessage'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
            backgroundColor: const Color(0xFFF8BBD0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error commenting: $e'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
          backgroundColor: const Color(0xFFF8BBD0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
            Navigator.pop(context, _isLiked || _blog['commentCount'] > (widget.blog['commentCount'] ?? 0));
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _blog['image'] != null &&
                _blog['image'].toString() != 'string' &&
                _blog['image'].toString().startsWith('data:image')
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                base64Decode(_blog['image'].toString().split(',').last),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(
                        Icons.account_box,
                        size: 64,
                        color: Colors.grey[500],
                      ),
                    ),
                  );
                },
              ),
            )
                : Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: Center(
                child: Icon(
                  Icons.account_box,
                  size: 64,
                  color: Colors.grey[500],
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
              children: [
                IconButton(
                  icon: Icon(
                    Icons.favorite,
                    size: 20,
                    color: _isLiked ? Colors.redAccent : Colors.black,
                  ),
                  onPressed: _isLoading || _isTogglingLike ? null : _toggleLike,
                ),
                Text(
                  '${_blog['likeCount'] ?? 0}',
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.comment,
                  size: 20,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_blog['commentCount'] ?? 0}',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                onPressed: _isLoading || !_isCommentButtonEnabled ? null : _commentBlog,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Comment'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}