import 'package:flutter/foundation.dart';
import 'package:tapp/models/app_user_profile.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  AppUserProfile? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  AppUserProfile? get currentUser => _currentUser;

  void login(String email) {
    if (_isLoggedIn) {
      return;
    }
    _isLoggedIn = true;
    _currentUser = _buildMockProfile(email);
    notifyListeners();
  }

  void logout() {
    if (!_isLoggedIn) {
      return;
    }
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }

  AppUserProfile _buildMockProfile(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    final usernamePart = normalizedEmail.split('@').first;
    final sanitized = usernamePart.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final handle = sanitized.isEmpty ? 'usuario_demo' : sanitized;

    final hash = normalizedEmail.codeUnits.fold<int>(0, (sum, code) {
      return (sum + code) % 1900000;
    });
    final followers = 100000 + hash;
    final followersText = followers >= 1000000
        ? '${(followers / 1000000).toStringAsFixed(1)} M'
        : '${(followers / 1000).toStringAsFixed(1)} K';

    return AppUserProfile(
      email: normalizedEmail,
      handle: '@$handle',
      followersLabel: '$followersText siguen esta cuenta',
    );
  }
}
