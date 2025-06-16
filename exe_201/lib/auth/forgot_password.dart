import 'dart:convert';

import 'package:flutter/material.dart';
import '/api/forgotpassword_api.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with SingleTickerProviderStateMixin {
  String _email = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward(); // Start the animation immediately
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
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

    // Define responsive scaling factors
    final horizontalPadding = screenWidth * 0.06; // 6% of screen width (24px on 400px screen)
    final spacingHeight = screenHeight * 0.02; // 2% of screen height
    final fontScaleFactor = screenWidth / 400; // Base font scaling (400px as reference)
    final buttonHeight = screenHeight * 0.07; // 7% of screen height (56px on 800px screen)

    return Scaffold(
      backgroundColor: const Color(0xFFF9ECEF),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF6F91)),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: spacingHeight * 2),
                      Text(
                        "Forgot Password",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontSize: 28 * fontScaleFactor.clamp(0.8, 1.2),
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
                      SizedBox(height: spacingHeight),
                      Text(
                        "Enter your email to reset your password",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1),
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: spacingHeight * 2),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _email = value.trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Email Address",
                          hintStyle: TextStyle(fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1)),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
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
                      SizedBox(height: spacingHeight * 1.6),
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight.clamp(48, 56),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter your email")),
                              );
                              return;
                            }
                            if (!_email.contains('@') || !_email.contains('.')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter a valid email address")),
                              );
                              return;
                            }
                            try {
                              final result = await ForgotPasswordApi.forgotPassword(
                                email: _email,
                              );
                              if (result['statusCode'] == 200) {
                                String token = result['body'] ?? '';
                                if (token.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Token not found in response. Please check your email.")),
                                  );
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Reset link sent to your email!")),
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ResetPasswordScreen(
                                      initialEmail: _email,
                                      initialToken: token,
                                    ),
                                  ),
                                );
                              } else {
                                String errorMessage = 'Failed to send reset link';
                                if (result['body'] != null && result['body'].isNotEmpty) {
                                  try {
                                    final errorBody = jsonDecode(result['body']);
                                    if (errorBody is List && errorBody.isNotEmpty) {
                                      errorMessage += ': ${errorBody[0]}';
                                    } else if (errorBody is Map && errorBody.containsKey('message')) {
                                      errorMessage += ': ${errorBody['message']}';
                                    } else if (errorBody is Map && errorBody.containsKey('error')) {
                                      errorMessage += ': ${errorBody['error']}';
                                    } else {
                                      errorMessage += ': ${errorBody.toString()}';
                                    }
                                  } catch (e) {
                                    errorMessage += ': ${result['body']} (Invalid JSON)';
                                  }
                                } else {
                                  errorMessage += ' (No details, Status Code: ${result['statusCode']})';
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(errorMessage)),
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
                                "Send Reset Link",
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
                            "Remembered your password? ",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Login",
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
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}