import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setDarkMode(bool isDarkMode) {
    final nextMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode == nextMode) {
      return;
    }

    _themeMode = nextMode;
    notifyListeners();
  }
}
