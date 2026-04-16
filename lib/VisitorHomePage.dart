import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'visitor_profile_page.dart';
import 'visitor_qr_page.dart';

class VisitorHomePage extends StatelessWidget {
  final String token;
  final String userId;

  const VisitorHomePage({required this.token, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Visitor Home")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 🔹 Chat Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(token: token),
                  ),
                );
              },
              child: Text("Open AI Chat"),
            ),

            SizedBox(height: 20),

            // 🔹 Profile Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VisitorProfilePage(
                      token: token,
                      userId: userId,
                    ),
                  ),
                );
              },
              child: Text("View Profile"),
            ),

            SizedBox(height: 20),

            // 🔹 QR Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VisitorQRPage(
                      token: token,
                      userId: userId,
                    ),
                  ),
                );
              },
              child: Text("Show QR Pass"),
            ),
          ],
        ),
      ),
    );
  }
}