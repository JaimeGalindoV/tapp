import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapp/pages/home.dart';
import 'package:tapp/pages/main_page.dart';
import 'package:tapp/pages/profile.dart';
import 'package:tapp/providers/likes_provider.dart';

void main() {
  testWidgets('Home renders Tinder-like swiper and action buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LikesProvider()),
        ],
        child: const MaterialApp(
          home: HomePage(),
        ),
      ),
    );

    expect(find.byType(CardSwiper), findsOneWidget);
    expect(find.byKey(const Key('home_card_swiper')), findsOneWidget);
    expect(find.bySemanticsLabel('Nopp!'), findsOneWidget);
    expect(find.bySemanticsLabel('Tapp!'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('Profile shows empty sections when there are no likes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LikesProvider()),
        ],
        child: const MaterialApp(
          home: ProfilePage(),
        ),
      ),
    );

    expect(find.text('Series'), findsOneWidget);
    expect(find.text('Peliculas'), findsOneWidget);
    expect(find.text('No likes yet in Series'), findsOneWidget);
    expect(find.text('No likes yet in Peliculas'), findsOneWidget);
  });

  testWidgets('Home Tapp adds likes and they appear on Profile', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LikesProvider()),
        ],
        child: const MaterialApp(
          home: MainPage(),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.favorite_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Peliculas'), findsOneWidget);
    expect(find.text('Dune: Part Two'), findsOneWidget);
  });
}

