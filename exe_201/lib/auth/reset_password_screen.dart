import 'package:exe_201/auth/login.dart';
import 'package:flutter/material.dart';
import '/api/resetpassword_api.dart';
import 'dart:convert';

class ResetPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialToken;

  const ResetPasswordScreen({super.key, this.initialEmail, this.initialToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> with SingleTickerProviderStateMixin {
  final _newPasswordController = TextEditingController();
  bool _isPasswordHidden = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions using MediaQuery
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Define responsive scaling factors
    final horizontalPadding = screenWidth * 0.06; // 6% of screen width
    final spacingHeight = screenHeight * 0.015; // 1.5% of screen height
    final fontScaleFactor = screenWidth / 400; // Base font scaling (400px as reference)
    final buttonHeight = screenHeight * 0.07; // 7% of screen height

    return Scaffold(
      backgroundColor: const Color(0xFFF9ECEF), // Soft pink background
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
                      SizedBox(height: spacingHeight * 2.5),
                      Text(
                        "Reset Password",
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
                        "Enter your new password",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1),
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: spacingHeight * 2.5),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: _isPasswordHidden,
                        decoration: InputDecoration(
                          hintText: "New Password",
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
                              color: Colors.pink.withOpacity(0.2),
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
                      SizedBox(height: spacingHeight * 2),
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight.clamp(48, 56),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_newPasswordController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter a new password")),
                              );
                              return;
                            }
                            if (widget.initialEmail == null || widget.initialToken == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Missing email or token. Please try again.")),
                              );
                              return;
                            }
                            String cleanToken = widget.initialToken!.trim();
                            if (cleanToken.startsWith('"') && cleanToken.endsWith('"')) {
                              cleanToken = cleanToken.substring(1, cleanToken.length - 1);
                            }
                            int paddingNeeded = (4 - cleanToken.length % 4) % 4;
                            final paddedToken = cleanToken + ('=' * paddingNeeded);
                            if (!ResetPasswordApi.isValidBase64(paddedToken)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Invalid token format. Please request a new reset link.")),
                              );
                              return;
                            }
                            try {
                              final result = await ResetPasswordApi.resetPassword(
                                email: widget.initialEmail!,
                                token: paddedToken,
                                newPassword: _newPasswordController.text,
                              );
                              if (result['statusCode'] == 200) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Password reset successfully!")),
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              } else {
                                String errorMessage = 'Failed to reset password';
                                try {
                                  final jsonResponse = jsonDecode(result['body']);
                                  errorMessage = jsonResponse['message'] ?? result['body'];
                                } catch (e) {
                                  errorMessage = result['body'];
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
                                "Reset Password",
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