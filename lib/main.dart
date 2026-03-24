import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapp/pages/home.dart';
import 'package:tapp/pages/login_page.dart';
import 'package:tapp/providers/auth_provider.dart';
import 'package:tapp/theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'Tapp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: authProvider.isLoggedIn ? const HomePage() : const LoginPage(),
    );
  }
}