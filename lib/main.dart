import 'package:flutter/material.dart';
import 'package:tapp/pages/home.dart';
import 'package:tapp/pages/login_page.dart';
import 'package:tapp/theme/app_theme.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;

  void _handleLoginSuccess() {
    setState(() => _isLoggedIn = true);
  }

  void _handleLogout() {
    setState(() => _isLoggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tapp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: _isLoggedIn
          ? HomePage(onLogout: _handleLogout)
          : LoginPage(onLoginSuccess: _handleLoginSuccess),
    );
  }
}