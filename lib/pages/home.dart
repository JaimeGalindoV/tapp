import 'package:flutter/material.dart';
import 'package:tapp/widgets/my_navigation_bar.dart';
import 'package:tapp/widgets/custom_app_bar.dart';

// This is a template to test nagivation but is necessary to create the home page.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Home",
      ),
      body: const Center(
        child: Text('Hello World'),
      ),
      bottomNavigationBar: const MyNavigationBar(),
    );
  }
}
