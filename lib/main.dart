import 'package:flutter/material.dart';
import 'package:srimca_ai/splash_screen.dart';
import 'package:srimca_ai/first.dart';
import 'package:srimca_ai/login_register_screen.dart';
import 'package:srimca_ai/welcome_screen.dart';
import 'package:srimca_ai/admin_dashboard.dart';
import 'package:srimca_ai/user_management.dart';
import 'package:srimca_ai/report_analytics_page.dart';
import 'package:srimca_ai/ai_monitaring_page.dart';
import 'package:srimca_ai/content_control_page.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SRIMCA AI Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // The initial route is '/' which points to SplashScreen
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/first': (context) => const FirstScreen(),
        '/login': (context) => const LoginRegisterScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/admin': (context) => const AdminDashboardWithSidebar(),
        '/user-management': (context) => const UserManagementPage(),
      },
    );
  }
}