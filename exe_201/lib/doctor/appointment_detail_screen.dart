import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:exe_201/config.dart';
class AppointmentDetailScreen extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _appointmentData;
  List<dynamic> _allFeedbackData = [];
  List<dynamic> _feedbackData = [];
  final _feedbackController = TextEditingController();
  int _rating = 0;
  int _currentPage = 1;
  int _pageSize = 5;
  int _totalPages = 1;

  static const String _baseUrl = '${AppConfig.apiBaseUrl}';

  @override
  void initState() {
    super.initState();
    _fetchAppointmentDetails();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('thành công') || message.contains('Đã mở')
            ? Colors.green // Màu xanh cho thành công
            : Colors.red, // Màu đỏ cho lỗi
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating, // Tùy chọn để SnackBar nổi
      ),
    );
  }

  Future<void> _fetchAppointmentDetails() async {
    setState(() {
      _isLoading = true;
    });

    final client = http.Client();
    try {
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        throw Exception('No access token found. Please log in.');
      }

      final response = await client.get(
        Uri.parse('$_baseUrl/api/appointment/${widget.appointmentId}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _appointmentData = json.decode(response.body);
          _isLoading = false;
        });
        await _fetchFeedbackData();
      } else {
        _showSnackBar('Lỗi khi lấy thông tin cuộc hẹn: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Lỗi không xác định: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      client.close();
    }
  }

  Future<void> _fetchFeedbackData() async {
    if (_appointmentData?['expertId'] == null) return;

    setState(() {
      _isLoading = true;
    });

    final client = http.Client();
    try {
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        throw Exception('No access token found. Please log in.');
      }

      _allFeedbackData.clear();
      int pageIndex = 1;
      while (true) {
        final response = await client.get(
          Uri.parse('$_baseUrl/api/appointment/feedback/expert/${_appointmentData!['expertId']}?pageIndex=$pageIndex&pageSize=10'),
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final items = data['items'] as List;
          _allFeedbackData.addAll(items);
          final totalItemsCount = data['totalItemsCount'] as int;
          _totalPages = (totalItemsCount / _pageSize).ceil();

          if (items.length < 10 || _allFeedbackData.length >= totalItemsCount) break;
          pageIndex++;
        } else {
          _showSnackBar('Lỗi khi lấy thông tin phản hồi: ${response.statusCode}');
          break;
        }
      }

      setState(() {
        _currentPage = 1;
        _updateCurrentFeedbackData();
        _isLoading = false;
      });
    } catch (e) {
      _showSnackBar('Lỗi không xác định khi lấy phản hồi: $e');
    } finally {
      client.close();
    }
  }

  void _updateCurrentFeedbackData() {
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    if (startIndex < _allFeedbackData.length) {
      _feedbackData = _allFeedbackData.sublist(
        startIndex,
        endIndex > _allFeedbackData.length ? _allFeedbackData.length : endIndex,
      );
    } else {
      _feedbackData = [];
      _currentPage = _totalPages > 0 ? _totalPages : 1;
    }
  }

  Future<void> _fetchAndOpenMeetingLink() async {
    setState(() {
      _isLoading = true;
    });

    final client = http.Client();
    try {
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        throw Exception('No access token found. Please log in.');
      }

      final appointmentResponse = await client.get(
        Uri.parse('$_baseUrl/api/appointment/${widget.appointmentId}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (appointmentResponse.statusCode == 200) {
        final appointmentData = json.decode(appointmentResponse.body);
        final appointmentTime = DateTime.parse(appointmentData['appointmentDate']);
        final meetingUrl = appointmentData['linkMeet'] as String? ?? '';
        final currentTime = DateTime.now();

        if (currentTime.isBefore(appointmentTime)) {
          _showSnackBar('Cuộc họp sẽ bắt đầu lúc ${appointmentTime.toLocal()}');
          return;
        }

        if (meetingUrl.isEmpty) {
          _showSnackBar('Không tìm thấy URL cuộc họp trong dữ liệu cuộc hẹn');
          return;
        }

        final Uri uri = Uri.parse(meetingUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          _showSnackBar('Đã mở liên kết cuộc họp thành công!');
        } else {
          _showSnackBar('Không thể mở URL: $meetingUrl');
        }
      } else {
        _showSnackBar('Lỗi khi lấy thông tin cuộc hẹn: ${appointmentResponse.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Lỗi không xác định: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      client.close();
    }
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty || _rating == 0) {
      _showSnackBar('Vui lòng nhập nội dung phản hồi và đánh giá sao.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final client = http.Client();
    try {
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        throw Exception('No access token found. Please log in.');
      }

      final appointmentResponse = await client.get(
        Uri.parse('$_baseUrl/api/appointment/${widget.appointmentId}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (appointmentResponse.statusCode == 200) {
        final appointmentData = json.decode(appointmentResponse.body);
        final appointmentTime = DateTime.parse(appointmentData['appointmentDate']);
        final endTime = appointmentTime.add(const Duration(hours: 1));
        final currentTime = DateTime.now();

        if (currentTime.isBefore(endTime)) {
          _showSnackBar('Vui lòng gửi phản hồi sau khi cuộc hợp kết thúc lúc ${endTime.toLocal()}');
          return;
        }
      } else {
        _showSnackBar('Lỗi khi kiểm tra thời gian cuộc hẹn: ${appointmentResponse.statusCode}');
        return;
      }

      final response = await client.post(
        Uri.parse('$_baseUrl/api/appointment/feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'content': _feedbackController.text.trim(),
          'stars': _rating,
          'appointmentId': widget.appointmentId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _feedbackController.clear();
          _rating = 0;
          _isLoading = false;
        });
        _showSnackBar('Phản hồi đã được gửi thành công!');
        await _fetchFeedbackData();
      } else {
        _showSnackBar('Lỗi khi gửi phản hồi: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Lỗi không xác định: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      client.close();
    }
  }

  Future<void> _createChatHub() async {
    setState(() {
      _isLoading = true;
    });

    final client = http.Client();
    try {
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      if (accessToken == null) {
        throw Exception('No access token found. Please log in.');
      }

      if (_appointmentData == null || _appointmentData!['expertId'] == null || _appointmentData!['content'] == null) {
        throw Exception('Appointment data or expertId/content is missing. Please ensure appointment details are loaded.');
      }

      final expertId = _appointmentData!['expertId'].toString();
      final expertResponse = await client.get(
        Uri.parse('$_baseUrl/api/expert/$expertId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (expertResponse.statusCode == 200) {
        final expertData = jsonDecode(expertResponse.body);
        final userId = expertData['userId'].toString();

        String nameChatHub = _appointmentData!['content'].toString().trim();
        if (nameChatHub.isEmpty) {
          nameChatHub = 'chat_default_${DateTime.now().millisecondsSinceEpoch}';
        } else {
          nameChatHub = nameChatHub.replaceAll(' ', '_');
          nameChatHub = '${nameChatHub}_${DateTime.now().millisecondsSinceEpoch}'.substring(0, nameChatHub.length > 50 ? 50 : nameChatHub.length);
        }

        if (nameChatHub.isEmpty) {
          throw Exception('Chat hub name cannot be empty.');
        }

        final uri = Uri.parse('$_baseUrl/api/chat/hub')
            .replace(queryParameters: {
          'secondUserId': userId,
          'nameChatHub': nameChatHub,
        });

        print('Request URL: $uri');

        final response = await client.post(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        );

        if (response.statusCode == 200) {
          _showSnackBar('Chat hub đã được tạo thành công!');
        } else if (response.statusCode == 409) {
          _showSnackBar('Chat hub đã tồn tại. Vui lòng thử lại với tên khác hoặc liên hệ hỗ trợ.');
        } else {
          final bodyText = response.body;
          if (bodyText.trim().isNotEmpty) {
            final errorBody = jsonDecode(bodyText);
            _showSnackBar('Lỗi khi tạo chat hub: ${response.statusCode} - ${errorBody.toString()}');
          } else {
            _showSnackBar('Lỗi khi tạo chat hub: ${response.statusCode} - Không có dữ liệu phản hồi.');
          }
        }
      } else {
        throw Exception('Lỗi khi lấy thông tin chuyên gia: ${expertResponse.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Lỗi khi tạo chat hub: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      client.close();
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.colorScheme.primary, theme.scaffoldBackgroundColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
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
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Card(
                          elevation: theme.cardTheme.elevation!,
                          shape: theme.cardTheme.shape,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chi tiết cuộc hẹn',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow('Thời gian', _appointmentData?['timeSlot'] ?? 'N/A', icon: Icons.schedule),
                                _buildInfoRow('Ngày', _formatDateTime(_appointmentData?['appointmentDate']), icon: Icons.calendar_today),
                                _buildInfoRow('Địa điểm', _appointmentData?['place'] ?? 'N/A', icon: Icons.location_on),
                                _buildInfoRow('Trạng thái', _appointmentData?['status'] ?? 'N/A', icon: Icons.info),
                                _buildInfoRow('Lý do', _appointmentData?['content'] ?? 'N/A', icon: Icons.description),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Icon(
                          Icons.favorite,
                          size: 40,
                          color: theme.colorScheme.primary.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Mở Cuộc Họp',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 24),
                        Card(
                          elevation: theme.cardTheme.elevation!,
                          shape: theme.cardTheme.shape,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _fetchAndOpenMeetingLink,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                  ),
                                  child: Text(
                                    'Mở Link Cuộc Họp',
                                    style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: _isLoading || _appointmentData == null ? null : _createChatHub,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.secondary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                  ),
                                  child: Text(
                                    'Tạo Chat Hub',
                                    style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Phản hồi của chuyên gia',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        if (_feedbackData.isEmpty)
                          Text(
                            'Chưa có phản hồi nào cho chuyên gia này.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                            textAlign: TextAlign.center,
                          )
                        else
                          Column(
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _feedbackData.length,
                                itemBuilder: (context, index) {
                                  final feedback = _feedbackData[index];
                                  return Card(
                                    elevation: theme.cardTheme.elevation!,
                                    shape: theme.cardTheme.shape,
                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: List.generate(5, (starIndex) {
                                              return Icon(
                                                Icons.star,
                                                size: 20,
                                                color: starIndex < feedback['stars']
                                                    ? theme.colorScheme.primary
                                                    : Colors.grey.withOpacity(0.5),
                                              );
                                            }),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            feedback['content'] ?? 'N/A',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Ngày: ${_formatDateTime(feedback['createdTime'])}',
                                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: _currentPage > 1
                                        ? () {
                                      setState(() {
                                        _currentPage--;
                                      });
                                      _updateCurrentFeedbackData();
                                    }
                                        : null,
                                  ),
                                  Text(
                                    'Trang $_currentPage / $_totalPages',
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward),
                                    onPressed: _currentPage < _totalPages
                                        ? () {
                                      setState(() {
                                        _currentPage++;
                                      });
                                      _updateCurrentFeedbackData();
                                    }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),
                        Text(
                          'Đánh giá cuộc họp',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 30),
                        Card(
                          elevation: theme.cardTheme.elevation!,
                          shape: theme.cardTheme.shape,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: _feedbackController,
                              maxLines: 1,
                              decoration: InputDecoration(
                                labelText: 'Nhập phản hồi của bạn',
                                border: theme.inputDecorationTheme.border,
                                labelStyle: theme.inputDecorationTheme.labelStyle,
                                filled: theme.inputDecorationTheme.filled,
                                fillColor: theme.inputDecorationTheme.fillColor,
                                focusedBorder: theme.inputDecorationTheme.focusedBorder,
                              ),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                Icons.star,
                                color: _rating > index
                                    ? theme.colorScheme.primary
                                    : Colors.grey.withOpacity(0.5),
                              ),
                              onPressed: () {
                                setState(() {
                                  _rating = index + 1;
                                });
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: theme.cardTheme.elevation!,
                          shape: theme.cardTheme.shape,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitFeedback,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                              ),
                              child: Text(
                                'Gửi Phản Hồi',
                                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary),
                              ),
                            ),
                          ),
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
            'Chi tiết cuộc hẹn',
            style: theme.appBarTheme.titleTextStyle,
          ),
        ],
      ),
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

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}