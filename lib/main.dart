import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:srimca_ai/splash_screen.dart';
import 'package:srimca_ai/first.dart';
import 'package:srimca_ai/login_register_screen.dart';
import 'package:srimca_ai/welcome_screen.dart';
import 'package:srimca_ai/admin_main_dashboard.dart';
import 'package:srimca_ai/user_management.dart';
import 'package:srimca_ai/faculty_dashboard.dart';
import 'package:srimca_ai/content_management_page.dart';
import 'package:srimca_ai/ai_monitoring_page.dart';
import 'package:srimca_ai/reports_analytics_page.dart';
import 'package:srimca_ai/security_page.dart';
import 'package:srimca_ai/VisitorHomePage.dart';
import 'package:srimca_ai/student_page.dart';
import 'package:srimca_ai/student_notifications_page.dart';
import 'package:srimca_ai/student_chat_history_page.dart';
import 'package:srimca_ai/push_notification_service.dart';

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
  await Firebase.initializeApp();
  
  // Initialize push notifications
  await PushNotificationService.initialize();
  
  runApp(const MyApp());
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

      themeMode: _themeMode,   // ⭐ dynamic now

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

      home: const SplashScreen(),
      onUnknownRoute: (settings) {
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
        '/first': (context) => const FirstScreen(),
        '/login': (context) => const LoginRegisterScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/admin': (context) => const AdminMainDashboard(),
        '/user-management': (context) => const UserManagementPage(),
        '/content-knowledge': (context) => const ContentManagementPage(),
        '/monitoring': (context) => const AIMonitoringPage(),
        '/reports': (context) => ReportsAnalyticsPage(),
        '/security': (context) => const SecurityMaintenancePage(),
        '/faculty': (context) => const FacultyHomePage(),
        '/visitor': (context) => VisitorHomePage(),
        '/student': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return StudentHomePage(
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
