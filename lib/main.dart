import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:employee_attendance/screens/splash_screen.dart';
import 'package:employee_attendance/screens/login_screen.dart';
import 'package:employee_attendance/screens/dashboard_screen.dart';
import 'package:employee_attendance/screens/admin_dashboard.dart';
import 'package:employee_attendance/screens/schedule_screen.dart';
import 'package:employee_attendance/screens/leave_request_screen.dart';
import 'package:employee_attendance/screens/attendance_history_screen.dart';
import 'package:employee_attendance/screens/expense_claims_screen.dart';
import 'package:employee_attendance/screens/profile_screen.dart';
import 'package:employee_attendance/utils/theme.dart';
import 'package:employee_attendance/services/auth_service.dart';
import 'screens/admin_notice_screen.dart';
import 'screens/employee_notice_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    debugPrint('Initializing AuthService...');
    await AuthService.init();
    debugPrint('AuthService initialized successfully');
  } catch (e) {
    debugPrint('Error initializing AuthService: $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
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
        if (!['/', '/login', '/dashboard', '/admin', '/schedule', '/request-leave', 
              '/attendance-history', '/expense-claims', '/profile', '/forgot-password', '/reset-password'].contains(settings.name)) {
          debugPrint('Route not found: ${settings.name}');
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: Text('Page Not Found: ${settings.name}'),
              ),
            ),
          );
        }
        return null; // Default to routes map
      },
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/admin': (context) => AdminDashboard(),
        '/schedule': (context) => ScheduleScreen(),
        '/request-leave': (context) => LeaveRequestScreen(),
        '/attendance-history': (context) => AttendanceHistoryScreen(),
        '/expense-claims': (context) => ExpenseClaimsScreen(),
        '/profile': (context) => ProfileScreen(),
        '/admin-notice': (context) => AdminNoticeScreen(),
        '/employee-notice': (context) => EmployeeNoticeScreen(),
         '/forgot-password': (context) => ForgotPasswordScreen(),
        '/reset-password': (context) => ResetPasswordScreen(),
        
      },
    );
  }
}
