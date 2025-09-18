import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/theme.dart';
import '../services/auth_service.dart';
import '../widgets/loading_widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isValidating = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start animations when screen loads
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _isValidating = true);
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _isValidating = false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.login(
        _employeeIdController.text,
        _passwordController.text,
      );

      if (response['success']) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        final userRole = response['user']['role'];
        if (userRole == 'admin' || userRole == 'hr') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        _showErrorDialog(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      _showErrorDialog('Login failed: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Signing you in...',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: Container(
                        height: 120,
                        child: Image.network(
                          'https://i.postimg.cc/TPV5kJKb/Frame-3.png',
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppTheme.lightBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.people,
                                size: 60,
                                color: AppTheme.primaryBlue,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Container(
                        height: 120,
                        child: Image.network(
                          'https://i.postimg.cc/sgPLsb80/Peoples.png',
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppTheme.lightBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.people,
                                size: 60,
                                color: AppTheme.primaryBlue,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Center(
                      child: Text(dotenv.env['API_URL'] ?? 'API_URL Not Found'),
                    ),
                    const SizedBox(height: 40),
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, double value, child) {
                        return Transform.translate(
                          offset: Offset(30 * (1 - value), 0),
                          child: Opacity(
                            opacity: value,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkGray,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 400),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Transform.translate(
                                offset: Offset(50 * (1 - value), 0),
                                child: Opacity(
                                  opacity: value,
                                  child: TextFormField(
                                    controller: _employeeIdController,
                                    enabled: !_isLoading,
                                    decoration: InputDecoration(
                                      labelText: 'Employee ID',
                                      prefixIcon: const Icon(Icons.badge, color: AppTheme.primaryBlue),
                                      suffixIcon: _isValidating 
                                        ? Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: LoadingWidgets.primaryLoader(size: 20),
                                          )
                                        : null,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your Employee ID';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      if (value.isNotEmpty && _isValidating) {
                                        setState(() => _isValidating = false);
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 500),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Transform.translate(
                                offset: Offset(50 * (1 - value), 0),
                                child: Opacity(
                                  opacity: value,
                                  child: TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    enabled: !_isLoading,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryBlue),
                                      suffixIcon: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_isValidating)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 8),
                                              child: LoadingWidgets.primaryLoader(size: 20),
                                            ),
                                          IconButton(
                                            icon: Icon(
                                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                              color: AppTheme.primaryBlue,
                                            ),
                                            onPressed: _isLoading ? null : () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 600),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Opacity(
                                opacity: value,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _isLoading ? null : () {
                                      Navigator.pushNamed(context, '/forgot-password');
                                    },
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(color: AppTheme.primaryBlue),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 30),
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 700),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Transform.scale(
                                scale: 0.8 + (0.2 * value),
                                child: Opacity(
                                  opacity: value,
                                  child: LoadingWidgets.loadingButton(
                                    text: 'LOGIN',
                                    onPressed: _handleLogin,
                                    isLoading: _isLoading,
                                    height: 55,
                                    borderRadius: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Uncomment if demo credentials are needed
                    // const SizedBox(height: 40),
                    // TweenAnimationBuilder(
                    //   duration: const Duration(milliseconds: 800),
                    //   tween: Tween<double>(begin: 0, end: 1),
                    //   builder: (context, double value, child) {
                    //     return Transform.translate(
                    //       offset: Offset(0, 30 * (1 - value)),
                    //       child: Opacity(
                    //         opacity: value,
                    //         child: Container(
                    //           padding: const EdgeInsets.all(16),
                    //           decoration: BoxDecoration(
                    //             color: AppTheme.lightBlue,
                    //             borderRadius: BorderRadius.circular(12),
                    //           ),
                    //           child: const Column(
                    //             crossAxisAlignment: CrossAxisAlignment.start,
                    //             children: [
                    //               Text(
                    //                 'Demo Credentials:',
                    //                 style: TextStyle(
                    //                   fontWeight: FontWeight.bold,
                    //                   color: AppTheme.darkGray,
                    //                 ),
                    //               ),
                    //               SizedBox(height: 8),
                    //               Text('Admin: admin123 / admin@123'),
                    //               Text('HR: hr123 / hr@123'),
                    //               Text('Employee: emp001 / emp@123'),
                    //             ],
                    //           ),
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}