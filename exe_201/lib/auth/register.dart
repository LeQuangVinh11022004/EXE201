import 'package:flutter/material.dart';
import '../api/register_api.dart';
import './login.dart';
import './register_expert.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  bool _isPasswordHidden = true;
  final _formKey = GlobalKey<FormState>();
  int _selectedRoleIndex = 0; // 0: Customer, 1: Expert
  
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  String? _selectedSex;

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
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _userNameController.dispose();
    _phoneNumberController.dispose();
    _dateOfBirthController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final registerResult = await RegisterApi.registerCustomer(
        email: _emailController.text,
        userName: _userNameController.text,
        password: _passwordController.text,
        phoneNumber: _phoneNumberController.text,
        fullName: _fullNameController.text,
        dateOfBirth: _dateOfBirthController.text,
        sex: _selectedSex!,
      );

      if (registerResult['statusCode'] == 200 || registerResult['statusCode'] == 201) {
        final confirmResult = await RegisterApi.confirmEmail(
          email: _emailController.text,
        );

        if (confirmResult['statusCode'] == 200 || confirmResult['statusCode'] == 201) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          ).then((_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đăng ký thành công'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            });
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
                      SizedBox(height: spacingHeight * 1.5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ToggleButtons(
                            isSelected: [_selectedRoleIndex == 0, _selectedRoleIndex == 1],
                            onPressed: (index) {
                              setState(() {
                                _selectedRoleIndex = index;
                              });
                              if (index == 1) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RegisterExpertScreen()),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            selectedColor: Colors.white,
                            fillColor: const Color(0xFFFF6F91),
                            borderColor: const Color(0xFFFF6F91),
                            selectedBorderColor: const Color(0xFFFF6F91),
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.0 * fontScaleFactor.clamp(0.8, 1.0),
                                  vertical: 12.0 * fontScaleFactor.clamp(0.8, 1.0),
                                ),
                                child: Text(
                                  'Customer',
                                  style: TextStyle(
                                    fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.0 * fontScaleFactor.clamp(0.8, 1.0),
                                  vertical: 12.0 * fontScaleFactor.clamp(0.8, 1.0),
                                ),
                                child: Text(
                                  'Expert',
                                  style: TextStyle(
                                    fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: spacingHeight * 1.5),
                      Text(
                        "Create Account",
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
                        "Join us to get started!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1),
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: spacingHeight * 2),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _fullNameController,
                              decoration: InputDecoration(
                                hintText: "Full Name",
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your full name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: spacingHeight * 1.5),
                            TextFormField(
                              controller: _userNameController,
                              decoration: InputDecoration(
                                hintText: "Username",
                                hintStyle: TextStyle(fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1)),
                                prefixIcon: const Icon(
                                  Icons.account_circle_outlined,
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a username';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: spacingHeight * 1.5),
                            TextFormField(
                              controller: _emailController,
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: spacingHeight * 1.5),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isPasswordHidden,
                              decoration: InputDecoration(
                                hintText: "Password",
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: spacingHeight * 1.5),
                            TextFormField(
                              controller: _phoneNumberController,
                              decoration: InputDecoration(
                                hintText: "Phone Number",
                                hintStyle: TextStyle(fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1)),
                                prefixIcon: const Icon(
                                  Icons.phone_outlined,
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
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: spacingHeight * 1.5),
                            TextFormField(
                              controller: _dateOfBirthController,
                              decoration: InputDecoration(
                                hintText: "Date of Birth (YYYY-MM-DD)",
                                hintStyle: TextStyle(fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1)),
                                prefixIcon: const Icon(
                                  Icons.calendar_today_outlined,
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
                              keyboardType: TextInputType.datetime,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your date of birth';
                                }
                                if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
                                  return 'Please use YYYY-MM-DD format';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: spacingHeight * 1.5),
                            DropdownButtonFormField<String>(
                              value: _selectedSex,
                              hint: Text(
                                "Select Sex",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1),
                                ),
                              ),
                              items: ['Male', 'Female', 'Other']
                                  .map((sex) => DropdownMenuItem(
                                        value: sex,
                                        child: Text(
                                          sex,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 16 * fontScaleFactor.clamp(0.9, 1.1),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSex = value;
                                });
                              },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.wc_outlined,
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
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select your sex';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: spacingHeight * 2),
                            SizedBox(
                              width: double.infinity,
                              height: buttonHeight.clamp(48, 56),
                              child: ElevatedButton(
                                onPressed: _register,
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
                                      "Register",
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
                            SizedBox(height: spacingHeight * 1.5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
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