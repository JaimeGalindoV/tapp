import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapp/pages/main_page.dart';
import 'package:tapp/providers/content_provider.dart';
import 'package:tapp/providers/likes_provider.dart';
import 'package:tapp/providers/user_profile_provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return SignInScreen(
            providers: [
              EmailAuthProvider(),
              GoogleProvider(
                clientId:
                    '702786780990-2c2i5cu0stk16n0na1s1gf21qfhth67m.apps.googleusercontent.com',
              ),
            ],
            headerBuilder: (context, constraints, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset(
                    isDarkMode
                        ? 'assets/images/TappLogoWhite.png'
                        : 'assets/images/TappLogoBlack.png',
                  ),
                ),
              );
            },
            subtitleBuilder: (context, action) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  action == AuthAction.signIn
                      ? 'Welcome to Tapp, please sign in!'
                      : 'Welcome to Tapp, please sign up!',
                ),
              );
            },
            footerBuilder: (context, action) {
              return const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'By signing in, you agree to our terms and conditions.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            },
            sideBuilder: (context, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('assets/images/TappLogoWhite.png'),
                ),
              );
            },
          );
        }
        return _AuthenticatedRoot(user: user);
      },
    );
  }
}

class _AuthenticatedRoot extends StatefulWidget {
  const _AuthenticatedRoot({required this.user});

  final User user;

  @override
  State<_AuthenticatedRoot> createState() => _AuthenticatedRootState();
}

class _AuthenticatedRootState extends State<_AuthenticatedRoot> {
  Future<void>? _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  @override
  void didUpdateWidget(covariant _AuthenticatedRoot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _bootstrapFuture = _bootstrap();
    }
  }

  Future<void> _bootstrap() async {
    final likesProvider = context.read<LikesProvider>();
    final contentProvider = context.read<ContentProvider>();
    final userProfileProvider = context.read<UserProfileProvider>();

    await likesProvider.bindUser(widget.user.uid);
    await Future.wait(<Future<void>>[
      contentProvider.loadContent(),
      userProfileProvider.bindUser(widget.user),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const MainPage();
      },
    );
  }
}
