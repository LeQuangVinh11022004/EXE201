import 'package:exe_201/expert/expert_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../nav/home_page.dart';
import 'forgot_password.dart';
import 'register.dart';
import '/api/login_api.dart';
import '/api/account_api.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions using MediaQuery
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Define responsive scaling factors
    final horizontalPadding = screenWidth * 0.06; // 6% of screen width (24px on 400px screen)
    final imageHeight = screenHeight * (isLandscape ? 0.25 : 0.22); // Smaller in landscape
    final spacingHeight = screenHeight * 0.02; // 2% of screen height
    final fontScaleFactor = screenWidth / 400; // Base font scaling (400px as reference)
    final buttonHeight = screenHeight * 0.07; // 7% of screen height (56px on 800px screen)

    return Scaffold(
      backgroundColor: const Color(0xFFF9ECEF), // Softer pink for modern, calming vibe
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: spacingHeight * 1.5), // Adjusted spacing
                  Image.asset(
                    'assets/momandbaby_login.jpg',
                    fit: BoxFit.cover,
                    height: imageHeight, // Responsive height
                    width: screenWidth, // Full screen width
                  ),
                  SizedBox(height: spacingHeight * 0.5),
                  Text(
                    "Mom&Baby",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 28 * fontScaleFactor.clamp(0.8, 1.2), // Responsive font size
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Color(0xFFFF6F91), Color(0xFF8B5CF6)],
                            ).createShader(
                              Rect.fromLTWH(0, 0, 200 * fontScaleFactor, 70),
                            ),
                        ),
                  ),
                  SizedBox(height: spacingHeight * 2),
                  TextField(

                    onChanged: (value) {
                      setState(() {
                        _username = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText:"Username" ,
                      hintStyle: TextStyle(fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1)),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Color(0xFFFF6F91),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.pink,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF6F91),
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 18 * fontScaleFactor.clamp(0.8, 1.0),
                        horizontal: 20 * fontScaleFactor.clamp(0.8, 1.0),
                      ),
                    ),
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1)),
                  ),
                  SizedBox(height: spacingHeight),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _password = value;
                      });
                    },
                    obscureText: _isPasswordHidden,
                    decoration: InputDecoration(
                      labelText: "Password",
                      hintStyle: TextStyle(fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1)),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFFFF6F91),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[500],
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordHidden = !_isPasswordHidden;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.pink,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF6F91),
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 18 * fontScaleFactor.clamp(0.8, 1.0),
                        horizontal: 20 * fontScaleFactor.clamp(0.8, 1.0),
                      ),
                    ),
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1)),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                        );
                      },
                      child: Text(
                        "Forgot password?",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: spacingHeight * 1.2),
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight.clamp(48, 56), // Responsive button height
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final result = await LoginApi.login(
                            userName: _username,
                            password: _password,
                          );
                          if (result['statusCode'] == 200 && result['accessToken'] != null) {
                            await storage.write(
                              key: 'access_token',
                              value: result['accessToken'],
                            );
                            final String accessToken = result['accessToken'];
                            Map<String, dynamic> decodedPayload = Jwt.parseJwt(accessToken);
                            final String role = decodedPayload['role'] ?? 'CUSTOMER';

                            final userResponse = await AccountApi.getCurrentUser(accessToken);
                            if (userResponse['statusCode'] == 200) {
                              final userData = userResponse['body'];
                              await storage.write(
                                key: 'user_id',
                                value: userData['id']?.toString(),
                              );
                            } else {
                              throw Exception('Failed to fetch user data: ${userResponse['body']}');
                            }

                            if (role == 'EXPERT') {
                              final userResponse = await AccountApi.getCurrentUser(accessToken);
                              if (userResponse['statusCode'] == 200) {
                                final userData = userResponse['body'];
                                final expertId = userData['expert']?['id']?.toString() ?? '';
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => ExpertScreen(accessToken: accessToken, expertId: expertId)),
                                      (route) => false,
                                );
                              } else {
                                throw Exception('Failed to fetch user data: ${userResponse['body']}');
                              }
                            } else {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const HomePage()),
                                    (route) => false,
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Login failed: ${result['body']}')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                              fontSize: 18 * fontScaleFactor.clamp(0.9, 1.1),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: spacingHeight * 1.2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Not a member? ",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: Text(
                          "Register now",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1),
                            color: const Color(0xFFFF6F91),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacingHeight * 1.2),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16 * fontScaleFactor.clamp(0.8, 1.0)),
                        child: Text(
                          "Or continue with",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14 * fontScaleFactor.clamp(0.9, 1.1),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  SizedBox(height: spacingHeight * 1.2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton(
                        icon: FontAwesomeIcons.google,
                        color: const Color(0xFFDB4437),
                        onPressed: () {},
                        iconSize: 24 * fontScaleFactor.clamp(0.8, 1.0),
                      ),
                      SizedBox(width: 20 * fontScaleFactor.clamp(0.8, 1.0)),
                      _buildSocialButton(
                        icon: Icons.apple,
                        color: Colors.black,
                        onPressed: () {},
                        iconSize: 24 * fontScaleFactor.clamp(0.8, 1.0),
                      ),
                      SizedBox(width: 20 * fontScaleFactor.clamp(0.8, 1.0)),
                      _buildSocialButton(
                        icon: FontAwesomeIcons.facebookF,
                        color: const Color(0xFF4267B2),
                        onPressed: () {},
                        iconSize: 24 * fontScaleFactor.clamp(0.8, 1.0),
                      ),
                    ],
                  ),
                  SizedBox(height: spacingHeight * 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required double iconSize,
  }) {
    final scaleFactor = MediaQuery.of(context).size.width / 400; // Reference width: 400px
    return IconButton(
      onPressed: onPressed,
      icon: Container(
        padding: EdgeInsets.all(12 * scaleFactor.clamp(0.8, 1.0)),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }
}