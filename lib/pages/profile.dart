import 'package:flutter/material.dart';
import 'package:tapp/widgets/custom_app_bar.dart';

// This is a template to test nagivation but is necessary to create the home page.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Profile",
      ),
      body: const Center(
        child: Text(
          'página de perfil',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
