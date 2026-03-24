import 'package:flutter/material.dart';
import 'package:tapp/pages/home.dart';
import 'package:tapp/pages/profile.dart';

// This is a template to test nagivation but is necessary to create the home page.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentPageIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    ProfilePage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentPageIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home), 
            label: "Home"
          ),
          NavigationDestination(
            icon: Icon(Icons.person), 
            label: "Profile"
          ),
        ]
      )
    );
  }
}
