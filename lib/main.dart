import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:employee_attendance/utils/theme.dart';
import 'package:employee_attendance/services/auth_service.dart';

// Screens
import 'package:employee_attendance/screens/splash_screen.dart';
import 'package:employee_attendance/screens/login_screen.dart';
import 'package:employee_attendance/screens/dashboard_screen.dart';
import 'package:employee_attendance/screens/admin_dashboard.dart';
import 'package:employee_attendance/screens/schedule_screen.dart';
import 'package:employee_attendance/screens/leave_request_screen.dart';
import 'package:employee_attendance/screens/attendance_history_screen.dart';
import 'package:employee_attendance/screens/expense_claims_screen.dart';
import 'package:employee_attendance/screens/profile_screen.dart';
import 'package:employee_attendance/screens/admin_notice_screen.dart';
import 'package:employee_attendance/screens/employee_notice_screen.dart';
import 'package:employee_attendance/screens/forgot_password_screen.dart';
import 'package:employee_attendance/screens/reset_password_screen.dart';

Future<void> main() async {
  // Make sure bindings are initialized *before* runZonedGuarded.
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(() async {
    // Load environment variables
    await dotenv.load(fileName: ".env");

    try {
      debugPrint('Initializing AuthService...');
      await AuthService.init();
      debugPrint('AuthService initialized successfully');
    } catch (e, st) {
      debugPrint('Error initializing AuthService: $e\n$st');
    }

    runApp(const MyApp());
  }, (error, stackTrace) {
    debugPrint('Unhandled error: $error\nStack trace: $stackTrace');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style safely.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'SWIZTECH Attendance',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        debugPrint('Navigating to route: ${settings.name}');

        // Validate known routes
        const validRoutes = <String>{
          '/',
          '/login',
          '/dashboard',
          '/admin',
          '/schedule',
          '/request-leave',
          '/attendance-history',
          '/expense-claims',
          '/profile',
          '/admin-notice',
          '/employee-notice',
          '/forgot-password',
          '/reset-password',
        };

        if (!validRoutes.contains(settings.name)) {
          debugPrint('Route not found: ${settings.name}');
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: Text('Page Not Found: ${settings.name}'),
              ),
            ),
          );
        }
        // Returning null allows MaterialApp to use the routes map below.
        return null;
      },
      routes: {
  '/': (_) => SplashScreen(),
  '/login': (_) => LoginScreen(),
  '/dashboard': (_) => DashboardScreen(),
  '/admin': (_) => AdminDashboard(),
  '/schedule': (_) => ScheduleScreen(),
  '/request-leave': (_) => LeaveRequestScreen(),
  '/attendance-history': (_) => AttendanceHistoryScreen(),
  '/expense-claims': (_) => ExpenseClaimsScreen(),
  '/profile': (_) => ProfileScreen(),
  '/admin-notice': (_) => AdminNoticeScreen(),
  '/employee-notice': (_) => EmployeeNoticeScreen(),
  '/forgot-password': (_) => ForgotPasswordScreen(),
  '/reset-password': (_) => ResetPasswordScreen(),
},

    );
  }
}
