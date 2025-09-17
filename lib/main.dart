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
import 'package:employee_attendance/screens/admin_notice_screen.dart';
import 'package:employee_attendance/screens/employee_notice_screen.dart';
import 'package:employee_attendance/screens/forgot_password_screen.dart';
import 'package:employee_attendance/screens/reset_password_screen.dart';
import 'package:employee_attendance/utils/theme.dart';
import 'package:employee_attendance/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
    if (dotenv.env['API_URL'] == null) {
      debugPrint('Error: API_URL not found in .env file');
    }
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }

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
  static final Map<String, WidgetBuilder> _routes = {
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
  };

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'SWIZTECH Attendance',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: _routes,
      onGenerateRoute: (settings) {
        debugPrint('Navigating to route: ${settings.name}, arguments: ${settings.arguments}');
        if (!_routes.containsKey(settings.name)) {
          debugPrint('Route not found: ${settings.name}');
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text('Page Not Found'),
                backgroundColor: AppTheme.primaryBlue,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Page Not Found: ${settings.name}',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.darkGray,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Back to Home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final protectedRoutes = ['/dashboard', '/admin', '/schedule', '/request-leave', '/attendance-history', '/expense-claims', '/profile', '/admin-notice', '/employee-notice'];
        if (protectedRoutes.contains(settings.name)) {
          final user = AuthService.getUser();
          if (user == null || AuthService.getToken() == null) {
            debugPrint('Unauthorized access to ${settings.name}, redirecting to /login');
            return MaterialPageRoute(
              builder: (context) => LoginScreen(),
            );
          }
          if (settings.name == '/admin' && user['role'] != 'admin' && user['role'] != 'hr') {
            debugPrint('Non-admin/HR user attempted to access /admin, redirecting to /dashboard');
            return MaterialPageRoute(
              builder: (context) => DashboardScreen(),
            );
          }
          if (settings.name == '/dashboard' && (user['role'] == 'admin' || user['role'] == 'hr')) {
            debugPrint('Admin/HR user attempted to access /dashboard, redirecting to /admin');
            return MaterialPageRoute(
              builder: (context) => AdminDashboard(),
            );
          }
        }
        return MaterialPageRoute(
          builder: _routes[settings.name]!,
          settings: settings,
        );
      },
      onUnknownRoute: (settings) {
        debugPrint('Unknown route: ${settings.name}');
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('Page Not Found'),
              backgroundColor: AppTheme.primaryBlue,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Page Not Found: ${settings.name}',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.darkGray,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}