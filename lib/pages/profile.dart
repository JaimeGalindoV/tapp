import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapp/models/app_user_profile.dart';
import 'package:tapp/models/swipe_content_item.dart';
import 'package:tapp/pages/detail.dart';
import 'package:tapp/providers/content_provider.dart';
import 'package:tapp/providers/likes_provider.dart';
import 'package:tapp/providers/user_profile_provider.dart';
import 'package:tapp/widgets/custom_app_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isContentVisible = true;
  bool _favoritesOnly = true;
  bool _sortNewestFirst = true;

  @override
  Widget build(BuildContext context) {
    final likesProvider = context.watch<LikesProvider>();
    final contentProvider = context.watch<ContentProvider>();
    final userProfileProvider = context.watch<UserProfileProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomScrollPadding = bottomInset + 100;
    final userProfile =
        userProfileProvider.profile ?? _fallbackUserProfile(_currentUserSafe);
    final items = _buildVisibleItems(likesProvider, contentProvider.items);
    final seriesItems = items
        .where((item) => item.type == ContentType.series)
        .toList(growable: false);
    final movieItems = items
        .where((item) => item.type == ContentType.movie)
        .toList(growable: false);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Profile'),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 10, 16, bottomScrollPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ProfileHeader(userProfile: userProfile),
                  const SizedBox(height: 20),
                  _ProfileActionRow(
                    isContentVisible: _isContentVisible,
                    favoritesOnly: _favoritesOnly,
                    sortNewestFirst: _sortNewestFirst,
                    onToggleContentVisible: () {
                      setState(() {
                        _isContentVisible = !_isContentVisible;
                      });
                    },
                    onToggleFavoritesOnly: () {
                      setState(() {
                        _favoritesOnly = !_favoritesOnly;
                      });
                    },
                    onToggleOrder: () {
                      setState(() {
                        _sortNewestFirst = !_sortNewestFirst;
                      });
                    },
                  ),
                  const SizedBox(height: 26),
                  if (!_isContentVisible)
                    Container(
                      key: const Key('profile_content_hidden_placeholder'),
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Contenido oculto',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else ...<Widget>[
                    _ContentSection(
                      title: 'Series',
                      items: seriesItems,
                      emptyLabel: _favoritesOnly
                          ? 'No tienes series favoritas todavía'
                          : 'No hay series disponibles',
                    ),
                    const SizedBox(height: 22),
                    _ContentSection(
                      title: 'Peliculas',
                      items: movieItems,
                      emptyLabel: _favoritesOnly
                          ? 'No tienes peliculas favoritas todavía'
                          : 'No hay peliculas disponibles',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshProfile() async {
    final user = _currentUserSafe;
    await context.read<ContentProvider>().refreshContent();
    if (user != null && mounted) {
      await context.read<UserProfileProvider>().bindUser(user);
    }
  }

  List<SwipeContentItem> _buildVisibleItems(
    LikesProvider likesProvider,
    List<SwipeContentItem> catalog,
  ) {
    final sourceItems = _favoritesOnly
        ? likesProvider.resolveLikedItems(catalog)
        : List<SwipeContentItem>.from(catalog, growable: false);

    if (_sortNewestFirst) {
      return List<SwipeContentItem>.from(sourceItems, growable: false);
    }

    return sourceItems.reversed.toList(growable: false);
  }

  AppUserProfile _fallbackUserProfile(User? user) {
    final email = (user?.email ?? 'demo@tapp.app').trim();
    final displayName = (user?.displayName ?? '').trim();
    final resolvedName = displayName.isNotEmpty
        ? displayName
        : (email.contains('@') ? email.split('@').first : 'usuario_demo');

    return AppUserProfile(
      uid: user?.uid ?? 'demo',
      email: email,
      displayName: resolvedName,
    );
  }

  User? get _currentUserSafe {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.userProfile});

  final AppUserProfile userProfile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        _ProfileAvatar(photoUrl: userProfile.photoUrl),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              userProfile.handle,
              key: const Key('profile_user_handle'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              userProfile.statsLabel,
              key: const Key('profile_user_followers'),
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = (photoUrl ?? '').trim();

    return Container(
      key: const Key('profile_user_avatar'),
      width: 52,
      height: 52,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainer,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: imageUrl.isEmpty
          ? _ProfileLogoAvatar(isDarkMode: isDarkMode)
          : _ProfileImage(photoUrl: imageUrl, isDarkMode: isDarkMode),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({required this.photoUrl, required this.isDarkMode});

  final String photoUrl;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    if (photoUrl.startsWith('http')) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _ProfileLogoAvatar(isDarkMode: isDarkMode);
        },
      );
    }

    final file = File(photoUrl);
    if (!file.existsSync()) {
      return _ProfileLogoAvatar(isDarkMode: isDarkMode);
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _ProfileLogoAvatar(isDarkMode: isDarkMode);
      },
    );
  }
}

class _ProfileLogoAvatar extends StatelessWidget {
  const _ProfileLogoAvatar({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        isDarkMode
            ? 'assets/images/LogoShortWhite.png'
            : 'assets/images/LogoShortBlack.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _ProfileActionRow extends StatelessWidget {
  const _ProfileActionRow({
    required this.isContentVisible,
    required this.favoritesOnly,
    required this.sortNewestFirst,
    required this.onToggleContentVisible,
    required this.onToggleFavoritesOnly,
    required this.onToggleOrder,
  });

  final bool isContentVisible;
  final bool favoritesOnly;
  final bool sortNewestFirst;
  final VoidCallback onToggleContentVisible;
  final VoidCallback onToggleFavoritesOnly;
  final VoidCallback onToggleOrder;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _ActionIcon(
          keyName: 'profile_btn_visibility',
          icon: isContentVisible
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          isActive: isContentVisible,
          onTap: onToggleContentVisible,
        ),
        const SizedBox(width: 10),
        _ActionIcon(
          keyName: 'profile_btn_favorites',
          icon: favoritesOnly ? Icons.favorite : Icons.favorite_border,
          isActive: favoritesOnly,
          onTap: onToggleFavoritesOnly,
        ),
        const SizedBox(width: 10),
        _ActionIcon(
          keyName: 'profile_btn_order',
          icon: Icons.history,
          isActive: !sortNewestFirst,
          onTap: onToggleOrder,
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.keyName,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final String keyName;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      key: Key(keyName),
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? colorScheme.surfaceContainerHigh
              : Colors.transparent,
          border: Border.all(
            color: isActive ? colorScheme.onSurface : colorScheme.outline,
            width: isActive ? 2 : 1.3,
          ),
        ),
        child: Icon(
          icon,
          color: colorScheme.onSurface,
          size: isActive ? 24 : 22,
        ),
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection({
    required this.title,
    required this.items,
    required this.emptyLabel,
  });

  final String title;
  final List<SwipeContentItem> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 31, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Container(
            key: Key('empty_$title'),
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            alignment: Alignment.center,
            child: Text(
              emptyLabel,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          SizedBox(
            height: 226,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _ProfilePosterCard(item: item);
              },
            ),
          ),
      ],
    );
  }
}

class _ProfilePosterCard extends StatelessWidget {
  const _ProfilePosterCard({required this.item});

  final SwipeContentItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('profile_tap_${item.id}'),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailPage(contentId: item.id)),
        );
      },
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  item.posterUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? const <Color>[
                                  Color(0xFF3A3A3A),
                                  Color(0xFF161616),
                                ]
                              : const <Color>[
                                  Color(0xFFE2E2E2),
                                  Color(0xFFBEBEBE),
                                ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
