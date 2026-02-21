import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:srimca_ai/splash_screen.dart';
import 'package:srimca_ai/first.dart';
import 'package:srimca_ai/login_register_screen.dart';
import 'package:srimca_ai/welcome_screen.dart';
import 'package:srimca_ai/admin_dashboard.dart';
import 'package:srimca_ai/user_management.dart';
import 'package:srimca_ai/faculty_dashboard.dart';
import 'package:srimca_ai/content_control_page.dart';
import 'package:srimca_ai/ai_monitoring_page.dart';
import 'package:srimca_ai/reports_analytics_page.dart';
import 'package:srimca_ai/security_page.dart';
import 'package:srimca_ai/VisitorHomePage.dart';
import 'package:srimca_ai/student_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
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
        '/admin': (context) => const AdminDashboard(),
        '/user-management': (context) => const UserManagementPage(),
        '/content-knowledge': (context) => const ContentControlPage(),
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
          );
        },
      },
    );
  }
}
