import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapp/models/app_user_profile.dart';
import 'package:tapp/models/swipe_content_item.dart';
import 'package:tapp/models/user_review.dart';
import 'package:tapp/pages/detail.dart';
import 'package:tapp/providers/content_provider.dart';
import 'package:tapp/providers/reviews_provider.dart';
import 'package:tapp/providers/theme_provider.dart';
import 'package:tapp/providers/user_profile_provider.dart';

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

  testWidgets('DetailPage shows retry state when content is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildDetailTestApp(
        contentProvider: FakeContentProvider(
          item: null,
          isLoading: false,
          errorMessage: 'Fallo de carga',
        ),
        reviewsProvider: FakeReviewsProvider(
          stream: const Stream<List<UserReview>>.empty(),
        ),
      ),
    );

    expect(find.text('Fallo de carga'), findsOneWidget);
    expect(find.text('Intentar de nuevo'), findsOneWidget);
  });

  testWidgets('DetailPage surfaces review stream errors', (tester) async {
    await tester.pumpWidget(
      _buildDetailTestApp(
        contentProvider: FakeContentProvider(item: _testItem),
        reviewsProvider: FakeReviewsProvider(
          stream: Stream<List<UserReview>>.error(Exception('boom')),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('No se pudieron cargar las reseñas.'), findsOneWidget);
    expect(find.text('Todavía no hay reseñas para este título.'), findsNothing);
  });
}

Widget _buildDetailTestApp({
  required ContentProvider contentProvider,
  required ReviewsProvider reviewsProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ContentProvider>.value(value: contentProvider),
      ChangeNotifierProvider<ReviewsProvider>.value(value: reviewsProvider),
      ChangeNotifierProvider<UserProfileProvider>.value(
        value: FakeUserProfileProvider(),
      ),
    ],
    child: const MaterialApp(
      home: DetailPage(contentId: 'm_test'),
    ),
  );
}

const SwipeContentItem _testItem = SwipeContentItem(
  id: 'm_test',
  title: 'Test Movie',
  posterUrl: 'https://example.com/poster.jpg',
  type: ContentType.movie,
  year: 2025,
  genres: <String>['Drama'],
  providers: <String>['Netflix'],
  rating: 4.5,
  overview: 'A test overview.',
);

class FakeContentProvider extends ChangeNotifier implements ContentProvider {
  FakeContentProvider({
    required this.item,
    this.isLoading = false,
    this.errorMessage,
  });

  final SwipeContentItem? item;

  @override
  final bool isLoading;

  @override
  final String? errorMessage;

  @override
  List<SwipeContentItem> get items =>
      item == null ? const <SwipeContentItem>[] : <SwipeContentItem>[item!];

  @override
  SwipeContentItem? getById(String contentId) {
    final currentItem = item;
    if (currentItem == null || currentItem.id != contentId) {
      return null;
    }
    return currentItem;
  }

  @override
  Future<void> ensureContentAvailable(String contentId) async {}

  @override
  Future<void> loadContent() async {}

  @override
  Future<void> refreshContent() async {}
}

class FakeReviewsProvider extends ChangeNotifier implements ReviewsProvider {
  FakeReviewsProvider({required this.stream});

  final Stream<List<UserReview>> stream;

  @override
  Future<void> deleteReview({
    required String contentId,
    required String userId,
  }) async {}

  @override
  Future<UserReview?> getUserReviewForContent({
    required String contentId,
    required String userId,
  }) async {
    return null;
  }

  @override
  Future<int> getUserReviewCount(String userId) async => 0;

  @override
  Future<void> upsertReview({
    required String contentId,
    required user,
    required String text,
  }) async {}

  @override
  Stream<List<UserReview>> watchReviews(String contentId) => stream;
}

class FakeUserProfileProvider extends ChangeNotifier
    implements UserProfileProvider {
  @override
  String? get errorMessage => null;

  @override
  bool get isLoading => false;

  @override
  AppUserProfile? get profile => null;

  @override
  Future<void> bindUser(user) async {}

  @override
  Future<void> refreshStats(user) async {}

  @override
  Future<void> saveProfile({
    required user,
    required String displayName,
    localPhoto,
  }) async {}
}
