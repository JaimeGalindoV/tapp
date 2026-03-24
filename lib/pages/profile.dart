import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapp/models/swipe_content_item.dart';
import 'package:tapp/providers/likes_provider.dart';
import 'package:tapp/widgets/custom_app_bar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final likesProvider = context.watch<LikesProvider>();

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Profile',
      ),
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ProfileHeader(),
                const SizedBox(height: 20),
                const _ProfileActionRow(),
                const SizedBox(height: 26),
                _ContentSection(
                  title: 'Series',
                  items: likesProvider.likedSeries,
                  emptyLabel: 'No likes yet in Series',
                ),
                const SizedBox(height: 22),
                _ContentSection(
                  title: 'Peliculas',
                  items: likesProvider.likedMovies,
                  emptyLabel: 'No likes yet in Peliculas',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

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
            border: Border.all(
              color: Colors.white12,
            ),
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
          children: const [
            Text(
              '@CUENTA_EJEMPLO',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '1.5 M siguen esta cuenta',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileActionRow extends StatelessWidget {
  const _ProfileActionRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _ActionIcon(icon: Icons.visibility_off_outlined),
        SizedBox(width: 10),
        _ActionIcon(icon: Icons.star_rounded),
        SizedBox(width: 10),
        _ActionIcon(icon: Icons.favorite_border, isActive: true),
        SizedBox(width: 10),
        _ActionIcon(icon: Icons.history),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    this.isActive = false,
  });

  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Icon(
        icon,
        color: Colors.white,
        size: isActive ? 24 : 22,
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
          style: const TextStyle(
            fontSize: 31,
            fontWeight: FontWeight.w700,
          ),
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
  const _ProfilePosterCard({
    required this.item,
  });

  final SwipeContentItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
