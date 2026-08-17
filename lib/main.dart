import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:srimca_ai/splash_screen.dart';
import 'package:srimca_ai/first.dart';
import 'package:srimca_ai/login_screen.dart';
import 'package:srimca_ai/register_screen.dart';
import 'package:srimca_ai/login_register_screen.dart';
import 'package:srimca_ai/welcome_screen.dart' as welcome;
import 'package:srimca_ai/admin_main_dashboard.dart';
import 'package:srimca_ai/user_management.dart';
import 'package:srimca_ai/faculty_dashboard.dart';
import 'package:srimca_ai/content_management_page.dart';
import 'package:srimca_ai/ai_monitoring_page.dart';
import 'package:srimca_ai/reports_analytics_page.dart';
import 'package:srimca_ai/security_page.dart';
import 'package:srimca_ai/visitor/visitor_home_screen.dart';
import 'package:srimca_ai/visitor/visitor_welcome_screen.dart';
import 'package:srimca_ai/visitor_registration_page.dart';
import 'package:srimca_ai/visitor_qr_page.dart';
import 'package:srimca_ai/student_page.dart' as student;
import 'package:srimca_ai/student_notifications_page.dart';
import 'package:srimca_ai/student_chat_history_page.dart';
import 'package:srimca_ai/push_notification_service.dart';
import 'package:srimca_ai/forgot_password_page.dart';
import 'package:srimca_ai/admin_password_requests_page.dart';
import 'package:srimca_ai/api_service.dart';


// App Theme Colors
class AppColors {
  static const Color appBar = Color(0xFF001F3F); // Navy Blue
  static const Color drawer = Color(0xFF1A237E); // Navy Blue (slightly lighter)
  static const Color background = Colors.white;
  static const Color card = Color(0xFFF5F5F5); // Light Grey
  static const Color button = Color(0xFF1E88E5); // Blue
  static const Color textPrimary = Color(0xFF212121); // Black / Dark Grey
  static const Color textSecondary = Color(0xFF757575); // Grey
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint('Firebase/Push notification initialization error: $e');
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Global error zone for uncaught async errors
  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stack) {
    debugPrint('Uncaught async error: $error');
    debugPrint('Stack: $stack');
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void changeTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SRIMCA AI Assistant',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.appBar,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.button,
          brightness: Brightness.light,
          primary: AppColors.appBar,
          secondary: AppColors.button,
          surface: AppColors.card,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.appBar,
          foregroundColor: Colors.white,
          elevation: 6,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: AppColors.drawer,
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.button,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: AppColors.appBar,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.button,
          brightness: Brightness.dark,
          primary: AppColors.button,
          secondary: AppColors.appBar,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.appBar,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
        useMaterial3: true,
      ),
builder: (context, child) {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: AppColors.button),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please reload the page or contact support.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => SystemNavigator.pop(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reload App'),
              ),
            ],
          ),
        ),
      ),
    );
  };

  return child!;
},
      onGenerateRoute: (settings) {
        final rawName = settings.name ?? '';
        final uri = Uri.parse(rawName);
        final path = uri.path.isEmpty ? rawName : uri.path;

        if (path == '/' || path.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const SplashScreen(),
            settings: settings,
          );
        }
        if (path == '/visitor-welcome' ||
            path == 'visitor-welcome' ||
            path == '/visitor-entry' ||
            path == 'visitor-entry') {
          return MaterialPageRoute(
            builder: (_) => const VisitorWelcomeScreen(),
            settings: settings,
          );
        }
        if (path == '/visitor' || path == 'visitor') {
          return MaterialPageRoute(
            builder: (_) => const VisitorHomeScreen(
              token: 'visitor',
              userId: 'visitor',
            ),
            settings: settings,
          );
        }
        if (path == '/first' || path == 'first') {
          return MaterialPageRoute(
            builder: (_) => const FirstScreen(),
            settings: settings,
          );
        }
        if (path == '/login' || path == 'login') {
          return MaterialPageRoute(
            builder: (_) => const LoginScreen(),
            settings: settings,
          );
        }
        if (path == '/register' ||
            path == 'register' ||
            path == '/visitor-register' ||
            path == 'visitor-register') {
          return MaterialPageRoute(
            builder: (_) => const RegisterScreen(initialRole: 'visitor'),
            settings: settings,
          );
        }
        return null;
      },
      onUnknownRoute: (settings) {
        final name = settings.name ?? '';
        if (name.contains('visitor-welcome') || name.contains('visitor-entry')) {
          return MaterialPageRoute(
            builder: (context) => const VisitorWelcomeScreen(),
          );
        }
        if (name.contains('visitor')) {
          return MaterialPageRoute(
            builder: (context) => const VisitorHomeScreen(token: 'visitor', userId: 'visitor'),
          );
        }
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Page not found: ${settings.name}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      routes: {
        '/': (context) => const SplashScreen(),
        '/first': (context) => const FirstScreen(),
        '/login': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return LoginScreen(
            initialRole: args?['role']?.toString() ?? args?['preselectRole']?.toString(),
          );
        },
        '/register': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return RegisterScreen(
            initialRole: args?['role']?.toString() ?? args?['preselectRole']?.toString(),
          );
        },
        '/login-register': (context) => const LoginScreen(),
        '/admin': (context) => const AdminMainDashboard(),
        '/user-management': (context) => const UserManagementPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/admin-password-requests': (context) => const AdminPasswordRequestsPage(),
        '/content-knowledge': (context) => const ContentManagementPage(),
        '/monitoring': (context) => const AIMonitoringPage(),
        '/reports': (context) => ReportsAnalyticsPage(),
        '/security': (context) => const SecurityMaintenancePage(),
        '/faculty': (context) => const FacultyHomePage(),
        '/visitor': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args != null &&
              args['userId'] != null &&
              args['token'] != null) {
            return VisitorHomeScreen(
              token: args['token']?.toString() ?? 'visitor',
              userId: args['userId']?.toString() ?? 'visitor',
              userName: args['userName']?.toString(),
            );
          }
          return FutureBuilder<Map<String, dynamic>?>(
            future: AuthService.getUser(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              return VisitorHomeScreen(
                token: 'visitor',
                userId: user?['_id']?.toString() ?? 'visitor',
                userName: user?['name']?.toString(),
              );
            },
          );
        },
        '/qr-scan': (context) => const VisitorQRPage(),
        '/visitor-register': (context) => const RegisterScreen(initialRole: 'visitor'),
        '/visitor-entry': (context) => const VisitorWelcomeScreen(),
        '/visitor-welcome': (context) => const VisitorWelcomeScreen(),
        '/student': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return student.StudentHomePage(
            studentName: args?['studentName'] ?? 'Student',
            semester: args?['semester'] ?? 'N/A',
            userId: args?['userId']?.toString() ?? '',
            email: args?['email']?.toString() ?? '',
            enrollmentNumber: args?['enrollmentNumber']?.toString(),
            course: args?['course']?.toString(),
          );
        },
        '/student-notifications': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return StudentNotificationsPage(
            userId: args?['userId']?.toString() ?? '',
          );
        },
        '/student-chat-history': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return StudentChatHistoryPage(
            userId: args?['userId']?.toString() ?? '',
          );
        },
      },
    );
  }
}

