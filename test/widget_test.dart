import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapp/models/app_user_profile.dart';
import 'package:tapp/models/swipe_content_item.dart';
import 'package:tapp/models/user_review.dart';
import 'package:tapp/providers/theme_provider.dart';

void main() {
  test('SwipeContentItem serializes new Firestore fields', () {
    const item = SwipeContentItem(
      id: 'm_test',
      title: 'Test Movie',
      posterUrl: 'https://example.com/poster.jpg',
      type: ContentType.movie,
      year: 2025,
      genres: <String>['Drama'],
      providers: <String>['Netflix', 'Prime Video'],
      rating: 4.5,
      overview: 'A test overview.',
      durationMinutes: 123,
      tmdbId: 999,
    );

    final data = item.toFirestore();

    expect(data['title'], 'Test Movie');
    expect(data['type'], 'movie');
    expect(data['providers'], <String>['Netflix', 'Prime Video']);
    expect(data['overview'], 'A test overview.');
    expect(data['tmdbId'], 999);
  });

  test('AppUserProfile exposes handle and stats label', () {
    const profile = AppUserProfile(
      uid: 'user_1',
      email: 'demo@tapp.app',
      displayName: 'demo_user',
      likesCount: 3,
      reviewsCount: 2,
    );

    expect(profile.handle, '@demo_user');
    expect(profile.statsLabel, '3 favoritos | 2 reseñas');
  });

  test('UserReview stores expected payload values', () {
    final review = UserReview(
      userId: 'user_1',
      userDisplayName: 'demo',
      text: 'Muy buena pelicula',
      createdAt: DateTime(2026, 5, 4),
    );

    final data = review.toFirestore();

    expect(data['userId'], 'user_1');
    expect(data['userDisplayName'], 'demo');
    expect(data['text'], 'Muy buena pelicula');
    expect(data.containsKey('updatedAt'), isTrue);
  });

  test('ThemeProvider toggles between dark and light', () {
    final provider = ThemeProvider();

    expect(provider.themeMode, ThemeMode.dark);
    provider.setDarkMode(false);
    expect(provider.themeMode, ThemeMode.light);
    provider.setDarkMode(true);
    expect(provider.themeMode, ThemeMode.dark);
  });
}
