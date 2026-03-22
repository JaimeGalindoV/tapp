import 'package:flutter/material.dart';

class MyNavigationBar extends StatefulWidget {
  const MyNavigationBar({super.key});

  @override
  State<MyNavigationBar> createState() => _MyNavigationBarState();
}

class _MyNavigationBarState extends State<MyNavigationBar> {
  var currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
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
      );
  }
}