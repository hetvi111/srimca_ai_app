import 'package:flutter/material.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Back button
          Positioned(
            top: 16,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              ),
            ),
          ),
          // 🌈 Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFB388FF),
                  Color(0xFF7C4DFF),
                ],
              ),
            ),
          ),

          // ☁ Optional Clouds (remove if not needed)
          Positioned(
            top: 40,
            left: -20,
            child: Image.asset(
              'assets/images/cloud.png',
              width: 200,
            ),
          ),
          Positioned(
            top: 80,
            right: -10,
            child: Image.asset(
              'assets/images/cloud.png',
              width: 200,
            ),
          ),

          // 🤖 Robot
          Positioned(
            top: 170,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/i1.png',
                height: 260,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // ⬜ White Curved Bottom Card
Align(
  alignment: Alignment.bottomCenter,
  child: Container(
    width: double.infinity,
    height: 320,
    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(36),
        topRight: Radius.circular(36),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title
        const Text(
          'Welcome to SAI!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        // Subtitle
        const Text(
          'Your personal assistant for smarter conversations\nfor learning, notes, and campus life.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            color: Colors.black54,
            height: 1.5,
          ),
        ),

        // 👇 Push button to bottom
        const Spacer(),

        // 🚀 Get Started Button (NOW AT BOTTOM)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),

        ],
      ),
    );
  }
}
