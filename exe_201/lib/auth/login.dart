// import giữ nguyên như bạn đã có
import 'package:exe_201/expert/expert_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../nav/home_page.dart';
import 'forgot_password.dart';
import 'register.dart';
import '/api/login_api.dart';
import '/api/account_api.dart';
import '/api/deal_api.dart';
import 'dart:math';
import '/api/appointment_api.dart';
import 'package:intl/intl.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isPasswordHidden = true;
  String _username = '';
  String _password = '';
  final FlutterSecureStorage storage = FlutterSecureStorage();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward(from: 0.0);
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (_) {},
    );
    final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (await androidPlugin?.areNotificationsEnabled() == false) {
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  Future<void> _showLoginNotification(String username) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'login_channel', 'Login Notifications',
        channelDescription: 'Login success',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      'Welcome back!',
      'Hello $username, you have successfully logged in.',
      details,
    );

    await _showRandomDealNotification();
    final userId = await storage.read(key: 'user_id');
    if (userId != null) {
      await _showTodayAppointmentNotification(userId);
    }
  }

  Future<void> _showRandomDealNotification() async {
    try {
      final deals = await DealApi.getDeals();
      final activeDeals = deals.where((d) => d['status'] == 'Active').toList();
      if (activeDeals.isEmpty) return;

      final randomDeal = activeDeals[Random().nextInt(activeDeals.length)];
      await flutterLocalNotificationsPlugin.show(
        1,
        'Hot Deal Alert!',
        '${randomDeal['name']}: ${randomDeal['description']}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'deal_channel', 'Deal Notifications',
            channelDescription: 'Deals you might love',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Deal error: $e');
    }
  }

  Future<void> _showTodayAppointmentNotification(String userId) async {
    try {
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      final appointments = await AppointmentApi.fetchAppointmentsByUserId(userId: userId, pageIndex: 0, pageSize: 10);
      final todayAppointments = appointments.where((appointment) {
        final date = DateTime.parse(appointment['appointmentDate']);
        final timeSlot = appointment['timeSlot'].split('-')[0];
        final time = DateFormat('HH:mm').parse(timeSlot);
        final start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        return date.toIso8601String().split('T')[0] == today && start.isAfter(now.subtract(const Duration(minutes: 1)));
      }).toList();

      if (todayAppointments.isNotEmpty) {
        final a = todayAppointments[0];
        await flutterLocalNotificationsPlugin.show(
          2,
          'Today’s Appointment!',
          '${a['content']} at ${a['timeSlot']} (${a['place']})',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'appointment_channel', 'Appointment Notifications',
              channelDescription: 'Your upcoming appointments',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
            macOS: DarwinNotificationDetails(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Appointment error: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final scale = screen.width / 400;
    final spacing = screen.height * 0.02;

    return Scaffold(
      backgroundColor: const Color(0xFFF9ECEF),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.asset(
                'assets/momandbaby_login.jpg',
                width: double.infinity,
                height: screen.height * 0.28,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screen.width * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: spacing * 1.2),
                    Text(
                      "Mom&Baby",
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 28 * scale.clamp(0.8, 1.2),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [Color(0xFFFF6F91), Color(0xFF8B5CF6)],
                          ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                      ),
                    ),
                    SizedBox(height: spacing * 1.5),
                    _buildTextField(Icons.person_outline, "Username", false),
                    SizedBox(height: spacing),
                    _buildTextField(Icons.lock_outline, "Password", true),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                        child: Text("Forgot password?", style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[600])),
                      ),
                    ),
                    SizedBox(height: spacing * 0.8),
                    _buildLoginButton(context, scale),
                    SizedBox(height: spacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Not a member? ", style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[600])),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: const Text("Register now", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6F91))),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Or continue with"),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                    SizedBox(height: spacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton(icon: FontAwesomeIcons.google, color: const Color(0xFFDB4437)),
                        const SizedBox(width: 20),
                        _buildSocialButton(icon: Icons.apple, color: Colors.black),
                        const SizedBox(width: 20),
                        _buildSocialButton(icon: FontAwesomeIcons.facebookF, color: const Color(0xFF4267B2)),
                      ],
                    ),
                    SizedBox(height: spacing * 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(IconData icon, String label, bool isPassword) {
    return TextField(
      onChanged: (value) {
        if (label == "Username") _username = value;
        if (label == "Password") _password = value;
      },
      obscureText: isPassword ? _isPasswordHidden : false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFF6F91)),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_isPasswordHidden ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
        )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.pink, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6F91), width: 2),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, double scale) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () async {
          try {
            if (_username.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a username')));
              return;
            }
            final result = await LoginApi.login(userName: _username, password: _password);
            if (result['statusCode'] == 200 && result['accessToken'] != null) {
              await storage.write(key: 'access_token', value: result['accessToken']);
              final String token = result['accessToken'];
              final data = Jwt.parseJwt(token);
              final role = data['role'] ?? 'CUSTOMER';
              final username = data['username'] ?? _username;

              final userRes = await AccountApi.getCurrentUser(token);
              if (userRes['statusCode'] == 200) {
                final userData = userRes['body'];
                await storage.write(key: 'user_id', value: userData['id'].toString());
                await _showLoginNotification(username);

                if (role == 'EXPERT') {
                  final expertId = userData['expert']?['id']?.toString() ?? '';
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => ExpertScreen(accessToken: token, expertId: expertId)),
                        (_) => false,
                  );
                } else {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                        (_) => false,
                  );
                }
              } else {
                throw Exception('User fetch failed: ${userRes['body']}');
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: ${result['body']}')));
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6F91), Color(0xFF8B5CF6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              "Login",
              style: TextStyle(
                fontSize: 18 * scale.clamp(0.9, 1.1),
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({required IconData icon, required Color color}) {
    return IconButton(
      onPressed: () {},
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
