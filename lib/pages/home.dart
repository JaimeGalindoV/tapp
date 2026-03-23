import 'package:flutter/material.dart';
import 'package:tapp/widgets/my_navigation_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tapp'),
        actions: [
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: const Center(
        child: Text('Hello World'),
      ),
      bottomNavigationBar: const MyNavigationBar(),
    );
  }
}
