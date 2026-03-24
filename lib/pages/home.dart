import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:tapp/data/swipe_content_data.dart';
import 'package:tapp/models/swipe_content_item.dart';
import 'package:tapp/providers/likes_provider.dart';
import 'package:tapp/theme/app_colors.dart';
import 'package:tapp/widgets/custom_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  void _swipeLeft() {
    _swiperController.swipe(CardSwiperDirection.left);
  }

  void _swipeRight() {
    _swiperController.swipe(CardSwiperDirection.right);
  }

  bool _handleSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (direction.isCloseTo(CardSwiperDirection.right)) {
      context.read<LikesProvider>().addLike(swipeContentItems[previousIndex]);
    }
    return true;
  }

  Widget _buildMovieCard(SwipeContentItem movie) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              movie.posterUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2C2C2C), Color(0xFF131313)],
                    ),
                  ),
                );
              },
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x99000000),
                    Color(0xDD000000),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movie.year} | ${movie.genres.join(' | ')}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Watch on',
                    key: Key('watch_on_label'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: movie.platforms
                        .map(
                          (platform) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              platform,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Home',
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
        child: Column(
          children: [
            Expanded(
              child: CardSwiper(
                key: const Key('home_card_swiper'),
                controller: _swiperController,
                cardsCount: swipeContentItems.length,
                numberOfCardsDisplayed: 3,
                isLoop: true,
                onSwipe: _handleSwipe,
                allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
                  horizontal: true,
                ),
                cardBuilder: (
                  context,
                  index,
                  horizontalOffsetPercentage,
                  verticalOffsetPercentage,
                ) {
                  return _buildMovieCard(swipeContentItems[index]);
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SwipeActionButton(
                  label: 'Nopp!',
                  icon: Icons.close_rounded,
                  backgroundColor: AppColors.brandPrimary,
                  startAngleInDegrees: -165,
                  sweepAngleInDegrees: 76,
                  radiusOffset: 14,
                  onTap: _swipeLeft,
                ),
                _SwipeActionButton(
                  label: 'Tapp!',
                  icon: Icons.favorite_rounded,
                  backgroundColor: const Color(0xFFFF0A63),
                  startAngleInDegrees: -100,
                  sweepAngleInDegrees: 82,
                  radiusOffset: 14,
                  onTap: _swipeRight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.startAngleInDegrees,
    required this.sweepAngleInDegrees,
    required this.radiusOffset,
    required this.onTap,
  });

  static const double _stackSize = 126;
  static const double _buttonSize = 98;

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final double startAngleInDegrees;
  final double sweepAngleInDegrees;
  final double radiusOffset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _stackSize,
      height: _stackSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Semantics(
                label: label,
                child: CustomPaint(
                  painter: _ArcTextPainter(
                    text: label,
                    textStyle: TextStyle(
                      color: backgroundColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                    startAngleInDegrees: startAngleInDegrees,
                    sweepAngleInDegrees: sweepAngleInDegrees,
                    center: const Offset(
                      _stackSize / 2,
                      _stackSize - (_buttonSize / 2),
                    ),
                    radius: (_buttonSize / 2) + radiusOffset,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onTap,
                child: Container(
                  width: _buttonSize,
                  height: _buttonSize,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: backgroundColor.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 58,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcTextPainter extends CustomPainter {
  const _ArcTextPainter({
    required this.text,
    required this.textStyle,
    required this.startAngleInDegrees,
    required this.sweepAngleInDegrees,
    required this.center,
    required this.radius,
  });

  final String text;
  final TextStyle textStyle;
  final double startAngleInDegrees;
  final double sweepAngleInDegrees;
  final Offset center;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty || radius <= 0) {
      return;
    }

    final characters = text.split('');
    final painters = characters
        .map(
          (char) => TextPainter(
            text: TextSpan(text: char, style: textStyle),
            textDirection: TextDirection.ltr,
          )..layout(),
        )
        .toList();

    final totalTextWidth = painters.fold<double>(
      0,
      (sum, painter) => sum + painter.width,
    );

    if (totalTextWidth == 0) {
      return;
    }

    final startAngle = _degToRad(startAngleInDegrees);
    final sweepAngle = _degToRad(sweepAngleInDegrees);
    final sign = sweepAngle >= 0 ? 1.0 : -1.0;
    final totalSweep = sweepAngle.abs();
    var currentAngle = startAngle;

    for (final painter in painters) {
      final charSweep = (painter.width / totalTextWidth) * totalSweep;
      final glyphAngle = currentAngle + (sign * charSweep / 2);
      final glyphOffset = Offset(
        center.dx + (radius * math.cos(glyphAngle)),
        center.dy + (radius * math.sin(glyphAngle)),
      );

      canvas.save();
      canvas.translate(glyphOffset.dx, glyphOffset.dy);
      canvas.rotate(glyphAngle + (sign * math.pi / 2));
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();

      currentAngle += sign * charSweep;
    }
  }

  static double _degToRad(double degrees) {
    return degrees * (math.pi / 180);
  }

  @override
  bool shouldRepaint(covariant _ArcTextPainter oldDelegate) {
    return text != oldDelegate.text ||
        textStyle != oldDelegate.textStyle ||
        startAngleInDegrees != oldDelegate.startAngleInDegrees ||
        sweepAngleInDegrees != oldDelegate.sweepAngleInDegrees ||
        center != oldDelegate.center ||
        radius != oldDelegate.radius;
  }
}

