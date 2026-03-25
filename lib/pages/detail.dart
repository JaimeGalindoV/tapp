import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapp/data/swipe_content_data.dart';
import 'package:tapp/models/swipe_content_item.dart';
import 'package:tapp/widgets/custom_app_bar.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.contentId});

  final String contentId;

  SwipeContentItem get content =>
      swipeContentItems.firstWhere((item) => item.id == contentId);

  @override
  Widget build(BuildContext context) {
    final item = content;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        showBackButton: true,
        logoCentered: true,
        showConfigButton: true,
        isOverlay: true,
      ),
      backgroundColor: colorScheme.surface,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  item.posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: colorScheme.surfaceContainerHigh,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 44,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDarkMode
                          ? const [
                              Color(0x12000000),
                              Color(0x520E0E11),
                              Color(0xFF0E0E11),
                              Color(0xFF0E0E11),
                            ]
                          : const [
                              Color(0x12000000),
                              Color(0x3FFFFFFF),
                              Color(0xFFF6F6F8),
                              Color(0xFFF6F6F8),
                            ],
                      stops: [0.0, 0.72, 0.96, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFE0C17A),
                          fontSize: 34,
                          height: 0.95,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${item.type == ContentType.movie ? 'Pelicula' : 'Serie'} · ${item.year} · ${item.genres.join(' · ')}',
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.white70
                              : colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.title} es una ${item.type == ContentType.movie ? 'pelicula' : 'serie'} de ${item.genres.join(', ')} estrenada en ${item.year}.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 20,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    ...List<Widget>.generate(5, (index) {
                      final star = index < item.rating.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded;
                      return Icon(star, color: colorScheme.onSurface, size: 31);
                    }),
                    const SizedBox(width: 10),
                    Text(
                      item.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatCommentCount(item.commentCount),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(width: 18),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _shareContent(item),
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.share_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'STREAMING en',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 24,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: item.platforms
                      .map(
                        (platform) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            platform,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 26),
                if (item.type == ContentType.movie &&
                    item.durationMinutes != null)
                  Text(
                    'Duracion: ${item.durationMinutes} min',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCommentCount(int count) {
    if (count < 1000) {
      return '+$count';
    }
    final inThousands = count / 1000;
    return '+${inThousands.toStringAsFixed(1)}k';
  }

  Future<void> _shareContent(SwipeContentItem item) async {
    final typeLabel = item.type == ContentType.movie ? 'pelicula' : 'serie';
    final message =
        'Te recomiendo $typeLabel: ${item.title} (${item.year})\n'
        'Generos: ${item.genres.join(', ')}\n'
        'Calificacion: ${item.rating.toStringAsFixed(1)}\n'
        'Disponible en: ${item.platforms.join(', ')}\n\n'
        'Visto en Tapp.';

    await Share.share(message, subject: 'Recomendacion: ${item.title}');
  }
}
