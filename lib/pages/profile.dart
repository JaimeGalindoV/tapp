import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapp/data/swipe_content_data.dart';
import 'package:tapp/models/app_user_profile.dart';
import 'package:tapp/models/swipe_content_item.dart';
import 'package:tapp/pages/detail.dart';
import 'package:tapp/providers/auth_provider.dart';
import 'package:tapp/providers/likes_provider.dart';
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
    final authProvider = context.watch<AuthProvider>();
    final userProfile = authProvider.currentUser ?? _fallbackUserProfile();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomScrollPadding = bottomInset + 100;
    final items = _buildVisibleItems(likesProvider);
    final seriesItems = items
        .where((item) => item.type == ContentType.series)
        .toList(growable: false);
    final movieItems = items
        .where((item) => item.type == ContentType.movie)
        .toList(growable: false);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Profile'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A2A2A), Color(0xFF141414)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 10, 16, bottomScrollPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Contenido oculto',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else ...[
                  _ContentSection(
                    title: 'Series',
                    items: seriesItems,
                    emptyLabel: _favoritesOnly
                        ? 'No likes yet in Series'
                        : 'No Series available',
                  ),
                  const SizedBox(height: 22),
                  _ContentSection(
                    title: 'Peliculas',
                    items: movieItems,
                    emptyLabel: _favoritesOnly
                        ? 'No likes yet in Peliculas'
                        : 'No Peliculas available',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<SwipeContentItem> _buildVisibleItems(LikesProvider likesProvider) {
    final sourceItems = _favoritesOnly
        ? likesProvider.likedItems
        : swipeContentItems;

    if (_sortNewestFirst) {
      return List<SwipeContentItem>.from(sourceItems, growable: false);
    }

    return sourceItems.reversed.toList(growable: false);
  }

  AppUserProfile _fallbackUserProfile() {
    return const AppUserProfile(
      email: 'demo@tapp.app',
      handle: '@usuario_demo',
      followersLabel: '0 siguen esta cuenta',
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.userProfile});

  final AppUserProfile userProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(color: Colors.white12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'assets/images/LogoShortWhite.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userProfile.handle,
              key: const Key('profile_user_handle'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              userProfile.followersLabel,
              key: const Key('profile_user_followers'),
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ],
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
      children: [
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
    return InkWell(
      key: Key(keyName),
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.white12 : Colors.transparent,
          border: Border.all(
            color: isActive ? Colors.white : Colors.white38,
            width: isActive ? 2 : 1.3,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: isActive ? 24 : 22),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            alignment: Alignment.center,
            child: Text(
              emptyLabel,
              style: const TextStyle(
                color: Colors.white70,
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
              separatorBuilder: (_, __) => const SizedBox(width: 12),
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
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  item.posterUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF3A3A3A), Color(0xFF161616)],
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
