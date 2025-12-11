import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Watchlist"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Login Successful!"),
            const Text("You are on the HomeScreen."),
            const SizedBox(height: 20),
            // Removing the underscore and .currentUser (since our getter returns the user directly)
            Text("User ID: ${AuthService().currentUser?.uid ?? 'N/A'}"),
            const Text("Home"),
          ],
        ),
      ),
    );
  }
}