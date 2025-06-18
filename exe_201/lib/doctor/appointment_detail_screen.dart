import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _appointmentData;
  final _feedbackController = TextEditingController();
  int _rating = 0;

  static const String _baseUrl = 'https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net';

  @override
  void initState() {
    super.initState();
    _fetchAppointmentDetails();
  }

  Future<void> _fetchAppointmentDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
      } else {
        setState(() {
          _errorMessage = 'Lỗi khi lấy thông tin cuộc hẹn: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi không xác định: $e';
        _isLoading = false;
      });
    } finally {
      client.close();
    }
  }

  Future<void> _fetchAndOpenMeetingLink() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
          setState(() {
            _errorMessage = 'Cuộc họp sẽ bắt đầu lúc ${appointmentTime.toLocal()}';
            _isLoading = false;
          });
          return;
        }

        if (meetingUrl.isEmpty) {
          setState(() {
            _errorMessage = 'Không tìm thấy URL cuộc họp trong dữ liệu cuộc hẹn';
            _isLoading = false;
          });
          return;
        }

        final Uri uri = Uri.parse(meetingUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          setState(() {
            _errorMessage = 'Không thể mở URL: $meetingUrl';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Lỗi khi lấy thông tin cuộc hẹn: ${appointmentResponse.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi không xác định: $e';
      });
    } finally {
      client.close();
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty || _rating == 0) {
      setState(() {
        _errorMessage = 'Vui lòng nhập nội dung phản hồi và đánh giá sao.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
          setState(() {
            _errorMessage = 'Vui lòng gửi phản hồi sau khi cuộc họp kết thúc lúc ${endTime.toLocal()}';
            _isLoading = false;
          });
          return;
        }
      } else {
        setState(() {
          _errorMessage = 'Lỗi khi kiểm tra thời gian cuộc hẹn: ${appointmentResponse.statusCode}';
          _isLoading = false;
        });
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
          _errorMessage = 'Phản hồi đã được gửi thành công!';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _errorMessage = null;
            });
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Lỗi khi gửi phản hồi: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi không xác định: $e';
      });
    } finally {
      client.close();
      setState(() {
        _isLoading = false;
      });
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
                      : _errorMessage != null
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchAppointmentDetails,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                      : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Appointment Details
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
                        // Meeting Section
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
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
                              ],
                            ),
                          ),
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