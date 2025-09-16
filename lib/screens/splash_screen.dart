import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:async';
import '../utils/theme.dart';
import '../services/auth_service.dart';
import 'package:local_auth/local_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.wait([
      _animationController.status.isCompleted
          ? Future.value()
          : _animationController.forward(),
      Future.delayed(const Duration(seconds: 3)),
    ]);

    if (!mounted) return;

    if (AuthService.isLoggedIn() && await AuthService.verifyToken()) {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isBiometricSupported = await _localAuth.isDeviceSupported();

      if (canCheckBiometrics && isBiometricSupported) {
        try {
          bool authenticated = await _localAuth.authenticate(
            localizedReason: 'Authenticate to access SWIZTECH Attendance',
            options: const AuthenticationOptions(
              useErrorDialogs: true,
              stickyAuth: true,
              biometricOnly: true,
            ),
          );

          if (authenticated) {
            final user = AuthService.getUser();
            final isAdmin = user?['role'] == 'admin';
            debugPrint('SplashScreen: Biometric authentication successful, admin: $isAdmin');
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                isAdmin ? '/admin' : '/dashboard',
              );
            }
          } else {
            debugPrint('SplashScreen: Biometric authentication failed');
            await AuthService.clearAuthData();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          }
        } catch (e) {
          debugPrint('Biometric authentication error: $e');
          await AuthService.clearAuthData();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      } else {
        debugPrint('SplashScreen: Biometrics not supported or unavailable');
        final user = AuthService.getUser();
        final isAdmin = user?['role'] == 'admin';
        debugPrint('SplashScreen: User logged in, admin: $isAdmin');
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            isAdmin ? '/admin' : '/dashboard',
          );
        }
      }
    } else {
      await AuthService.clearAuthData();
      debugPrint('SplashScreen: User not logged in or invalid token');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.secondaryBlue,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.network(
                            'https://i.postimg.cc/zGmmJCf3/Rectangle-1.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Error loading splash image: $error');
                              return const Icon(
                                Icons.business,
                                size: 60,
                                color: AppTheme.primaryBlue,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'SWIZTECH',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: const Text(
                    'Precision Attendance in Your Pocket',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
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
}