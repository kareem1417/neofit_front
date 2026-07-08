import 'package:flutter/material.dart';

class AiAdvisorChatScreen extends StatelessWidget {
  const AiAdvisorChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF070B0D),
      body: SafeArea(
        child: Center(
          child: Text(
            'AI Advisor coming soon',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
