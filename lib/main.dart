import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapp/pages/login_page.dart';
import 'package:tapp/pages/main_page.dart';
import 'package:tapp/providers/auth_provider.dart';
import 'package:tapp/providers/likes_provider.dart';
import 'package:tapp/providers/theme_provider.dart';
import 'package:tapp/theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LikesProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Tapp',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      home: authProvider.isLoggedIn ? const MainPage() : const LoginPage(),
    );
  }
}
