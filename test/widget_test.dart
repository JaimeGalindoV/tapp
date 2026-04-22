import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapp/data/swipe_content_data.dart';
import 'package:tapp/pages/config_page.dart';
import 'package:tapp/pages/detail.dart';
import 'package:tapp/pages/edit_profile_page.dart';
import 'package:tapp/pages/home.dart';
import 'package:tapp/pages/main_page.dart';
import 'package:tapp/pages/profile.dart';
import 'package:tapp/providers/likes_provider.dart';
import 'package:tapp/providers/theme_provider.dart';
import 'package:tapp/theme/app_theme.dart';

void main() {
  Future<void> pumpWithProviders(
    WidgetTester tester, {
    required Widget home,
    LikesProvider? likesProvider,
    ThemeProvider? themeProvider,
  }) async {
    final likes = likesProvider ?? LikesProvider();
    final theme = themeProvider ?? ThemeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LikesProvider>.value(value: likes),
          ChangeNotifierProvider<ThemeProvider>.value(value: theme),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.themeMode,
          home: home,
        ),
      ),
    );
  }

  testWidgets('Home renders fullscreen swiper with metadata', (
    WidgetTester tester,
  ) async {
    await pumpWithProviders(tester, home: const HomePage());

    expect(find.byType(CardSwiper), findsOneWidget);
    expect(find.byKey(const Key('home_card_swiper')), findsOneWidget);
    expect(find.byKey(const Key('watch_on_label')), findsWidgets);
    expect(find.textContaining('2024'), findsOneWidget);
    expect(find.text('Max'), findsWidgets);
    expect(find.text('Prime Video'), findsWidgets);

    final initialOpacity = tester.widget<AnimatedOpacity>(
      find.byKey(const Key('home_swipe_feedback_opacity')),
    );
    expect(initialOpacity.opacity, 0);
  });

  testWidgets(
    'Home feedback appears only after swipe and hides after 1 second',
    (WidgetTester tester) async {
      await pumpWithProviders(tester, home: const HomePage());

      final initialOpacity = tester.widget<AnimatedOpacity>(
        find.byKey(const Key('home_swipe_feedback_opacity')),
      );
      expect(initialOpacity.opacity, 0);

      final swiperFinder = find.byKey(const Key('home_card_swiper'));
      final gesture = await tester.startGesture(tester.getCenter(swiperFinder));
      await gesture.moveBy(const Offset(70, 0));
      await tester.pump();

      final dragOpacity = tester.widget<AnimatedOpacity>(
        find.byKey(const Key('home_swipe_feedback_opacity')),
      );
      expect(dragOpacity.opacity, 0);

      await gesture.up();
      await tester.pumpAndSettle();

      await tester.fling(swiperFinder, const Offset(1000, 0), 4000);

      var becameVisible = false;
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        final opacity = tester.widget<AnimatedOpacity>(
          find.byKey(const Key('home_swipe_feedback_opacity')),
        );
        if (opacity.opacity == 1) {
          becameVisible = true;
          break;
        }
      }
      expect(becameVisible, true);

      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 260));
      final hiddenOpacity = tester.widget<AnimatedOpacity>(
        find.byKey(const Key('home_swipe_feedback_opacity')),
      );
      expect(hiddenOpacity.opacity, 0);
    },
  );

  testWidgets(
    'Profile has 3 controls without star and visibility toggle works',
    (WidgetTester tester) async {
      await pumpWithProviders(tester, home: const ProfilePage());

      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.byKey(const Key('profile_btn_visibility')), findsOneWidget);
      expect(find.byKey(const Key('profile_btn_favorites')), findsOneWidget);
      expect(find.byKey(const Key('profile_btn_order')), findsOneWidget);
      expect(find.text('Series'), findsOneWidget);
      expect(find.text('Peliculas'), findsOneWidget);

      await tester.tap(find.byKey(const Key('profile_btn_visibility')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('profile_content_hidden_placeholder')),
        findsOneWidget,
      );
      expect(find.text('Series'), findsNothing);
      expect(find.text('Peliculas'), findsNothing);
    },
  );

  testWidgets('Profile favorites toggle can show full catalog when no likes', (
    WidgetTester tester,
  ) async {
    await pumpWithProviders(tester, home: const ProfilePage());

    expect(find.text('No likes yet in Peliculas'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile_btn_favorites')));
    await tester.pumpAndSettle();

    expect(find.text('Dune: Part Two'), findsOneWidget);
  });

  testWidgets('Profile order toggle alternates newest and oldest likes', (
    WidgetTester tester,
  ) async {
    final likesProvider = LikesProvider()
      ..addLike(swipeContentItems[0])
      ..addLike(swipeContentItems[3]);

    await pumpWithProviders(
      tester,
      home: const ProfilePage(),
      likesProvider: likesProvider,
    );

    final poorThings = find.byKey(const Key('profile_tap_m_poor_things'));
    final dune = find.byKey(const Key('profile_tap_m_dune_2'));
    expect(poorThings, findsOneWidget);
    expect(dune, findsOneWidget);
    expect(
      tester.getTopLeft(poorThings).dx,
      lessThan(tester.getTopLeft(dune).dx),
    );

    await tester.tap(find.byKey(const Key('profile_btn_order')));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(dune).dx,
      lessThan(tester.getTopLeft(poorThings).dx),
    );
  });

  testWidgets('Profile header shows fallback user info', (WidgetTester tester) async {
    await pumpWithProviders(tester, home: const ProfilePage());
    expect(find.byKey(const Key('profile_user_avatar')), findsOneWidget);
    expect(find.byKey(const Key('profile_user_handle')), findsOneWidget);
    expect(find.text('@usuario_demo'), findsOneWidget);
    expect(find.byKey(const Key('profile_user_followers')), findsOneWidget);
    expect(find.text('0 siguen esta cuenta'), findsOneWidget);
  });

  testWidgets('MainPage keeps transparent overlay navigation bar', (
    WidgetTester tester,
  ) async {
    await pumpWithProviders(tester, home: const MainPage());

    final mainScaffold = tester.widget<Scaffold>(
      find.byKey(const Key('main_page_scaffold')),
    );
    expect(mainScaffold.extendBody, true);

    final navigationBar = tester.widget<NavigationBar>(
      find.byKey(const Key('main_navigation_bar')),
    );
    expect(navigationBar.backgroundColor, Colors.transparent);
    expect(navigationBar.surfaceTintColor, Colors.transparent);
    expect(navigationBar.shadowColor, Colors.transparent);
  });

  testWidgets('Home swipe right adds likes and they appear on Profile', (
    WidgetTester tester,
  ) async {
    await pumpWithProviders(tester, home: const MainPage());

    await tester.drag(
      find.byKey(const Key('home_card_swiper')),
      const Offset(260, 0),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Peliculas'), findsOneWidget);
    expect(find.text('Dune: Part Two'), findsOneWidget);
  });

  testWidgets('Tap on Home card opens DetailPage with content id', (
    WidgetTester tester,
  ) async {
    await pumpWithProviders(tester, home: const HomePage());

    await tester.tap(find.byKey(const Key('home_tap_m_dune_2')));
    await tester.pumpAndSettle();

    expect(find.byType(DetailPage), findsOneWidget);
    final detailPage = tester.widget<DetailPage>(find.byType(DetailPage));
    expect(detailPage.contentId, 'm_dune_2');
  });

  testWidgets('Tap on Profile poster opens DetailPage with content id', (
    WidgetTester tester,
  ) async {
    final likesProvider = LikesProvider()..addLike(swipeContentItems[0]);

    await pumpWithProviders(
      tester,
      home: const ProfilePage(),
      likesProvider: likesProvider,
    );

    await tester.ensureVisible(find.text('Dune: Part Two'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dune: Part Two'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailPage), findsOneWidget);
    final detailPage = tester.widget<DetailPage>(find.byType(DetailPage));
    expect(detailPage.contentId, 'm_dune_2');
  });

  testWidgets('ConfigPage theme switch updates ThemeProvider mode', (
    WidgetTester tester,
  ) async {
    final themeProvider = ThemeProvider();

    await pumpWithProviders(
      tester,
      home: const ConfigPage(),
      themeProvider: themeProvider,
    );

    expect(find.byKey(const Key('config_theme_switch_tile')), findsOneWidget);
    expect(find.byKey(const Key('config_edit_profile_tile')), findsOneWidget);
    expect(find.text('Editar perfil'), findsOneWidget);
    expect(themeProvider.isDarkMode, true);
    expect(find.text('Activado'), findsOneWidget);

    await tester.tap(find.byKey(const Key('config_theme_switch_tile')));
    await tester.pumpAndSettle();

    expect(themeProvider.isDarkMode, false);
    expect(find.text('Desactivado'), findsOneWidget);
  });

  testWidgets('ConfigPage opens EditProfilePage from edit profile option', (
    WidgetTester tester,
  ) async {
    await pumpWithProviders(tester, home: const ConfigPage());

    await tester.tap(find.byKey(const Key('config_edit_profile_tile')));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfilePage), findsOneWidget);
    expect(find.text('Editar perfil'), findsOneWidget);
    expect(find.byKey(const Key('config_email_text')), findsOneWidget);
    expect(find.byKey(const Key('config_display_name_field')), findsOneWidget);
    expect(find.byKey(const Key('config_photo_url_field')), findsOneWidget);
    expect(
      find.byKey(const Key('config_change_password_button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('config_save_profile_button')), findsOneWidget);
  });

  testWidgets('EditProfilePage opens change password dialog', (
    WidgetTester tester,
  ) async {
    await pumpWithProviders(tester, home: const EditProfilePage());

    await tester.tap(find.byKey(const Key('config_change_password_button')));
    await tester.pumpAndSettle();

    expect(find.text('Cambiar contraseña'), findsWidgets);
    expect(
      find.byKey(const Key('change_password_current_field')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('change_password_new_field')), findsOneWidget);
    expect(
      find.byKey(const Key('change_password_repeat_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('change_password_submit_button')),
      findsOneWidget,
    );
  });

  testWidgets('EditProfilePage keeps dialog open when passwords do not match', (
    WidgetTester tester,
  ) async {
    await pumpWithProviders(tester, home: const EditProfilePage());

    await tester.tap(find.byKey(const Key('config_change_password_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('change_password_current_field')),
      'actual123',
    );
    await tester.enterText(
      find.byKey(const Key('change_password_new_field')),
      'nueva123',
    );
    await tester.enterText(
      find.byKey(const Key('change_password_repeat_field')),
      'distinta123',
    );
    await tester.tap(find.byKey(const Key('change_password_submit_button')));
    await tester.pump();

    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(
      find.byKey(const Key('change_password_current_field')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('change_password_new_field')), findsOneWidget);
    expect(
      find.byKey(const Key('change_password_repeat_field')),
      findsOneWidget,
    );
  });

  testWidgets(
    'ConfigPage logout pops back to previous route',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LikesProvider>.value(value: LikesProvider()),
            ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ConfigPage()),
                        );
                      },
                      child: const Text('open_config'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('open_config'));
      await tester.pumpAndSettle();
      expect(find.byType(ConfigPage), findsOneWidget);

      await tester.tap(find.byKey(const Key('config_logout_tile')));
      await tester.pumpAndSettle();

      expect(find.text('open_config'), findsOneWidget);
      expect(find.byType(ConfigPage), findsNothing);
    },
  );
}
