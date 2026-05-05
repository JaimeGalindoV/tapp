import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapp/firebase_options.dart';
import 'package:tapp/pages/auth_gate.dart';
import 'package:tapp/providers/content_provider.dart';
import 'package:tapp/providers/likes_provider.dart';
import 'package:tapp/providers/reviews_provider.dart';
import 'package:tapp/providers/theme_provider.dart';
import 'package:tapp/providers/user_profile_provider.dart';
import 'package:tapp/repositories/content_repository.dart';
import 'package:tapp/repositories/likes_repository.dart';
import 'package:tapp/repositories/reviews_repository.dart';
import 'package:tapp/repositories/user_repository.dart';
import 'package:tapp/services/tmdb_service.dart';
import 'package:tapp/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TmdbService>(create: (_) => TmdbService()),
        Provider<LikesRepository>(create: (_) => LikesRepository()),
        Provider<ReviewsRepository>(create: (_) => ReviewsRepository()),
        Provider<UserRepository>(create: (_) => UserRepository()),
        Provider<ContentRepository>(
          create: (context) =>
              ContentRepository(tmdbService: context.read<TmdbService>()),
        ),
        ChangeNotifierProvider<LikesProvider>(
          create: (context) =>
              LikesProvider(repository: context.read<LikesRepository>()),
        ),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<ContentProvider>(
          create: (context) =>
              ContentProvider(repository: context.read<ContentRepository>())
                ..loadContent(),
        ),
        ChangeNotifierProvider<ReviewsProvider>(
          create: (context) =>
              ReviewsProvider(repository: context.read<ReviewsRepository>()),
        ),
        ChangeNotifierProvider<UserProfileProvider>(
          create: (context) => UserProfileProvider(
            userRepository: context.read<UserRepository>(),
            likesRepository: context.read<LikesRepository>(),
            reviewsRepository: context.read<ReviewsRepository>(),
          ),
        ),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Tapp',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      home: const AuthGate(),
    );
  }
}
