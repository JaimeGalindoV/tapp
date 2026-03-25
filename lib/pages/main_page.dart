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
  static const double _bottomNavigationHeight = 78;
  int _currentPageIndex = 0;

  final List<Widget> _pages = [HomePage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isHomeSelected = _currentPageIndex == 0;
    final Color selectedColor = isHomeSelected
        ? Colors.white
        : colorScheme.onSurface;
    final Color unselectedColor = isHomeSelected
        ? Colors.white.withValues(alpha: 0.78)
        : colorScheme.onSurfaceVariant;

    return Scaffold(
      key: const Key('main_page_scaffold'),
      extendBody: true,
      body: _pages[_currentPageIndex],
      bottomNavigationBar: NavigationBar(
        key: const Key('main_navigation_bar'),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: selectedColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            );
          }
          return TextStyle(
            color: unselectedColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          );
        }),
        height: _bottomNavigationHeight,
        selectedIndex: _currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home, color: unselectedColor),
            selectedIcon: Icon(Icons.home, color: selectedColor),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person, color: unselectedColor),
            selectedIcon: Icon(Icons.person, color: selectedColor),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
