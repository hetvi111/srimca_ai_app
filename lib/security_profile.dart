import 'package:flutter/material.dart';

class SecurityPages extends StatelessWidget {
  const SecurityPages({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Security")),
      body: const Center(
        child: Text("Security Settings Page"),
      ),
    );
  }
}
