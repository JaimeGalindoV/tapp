import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:tapp/data/swipe_content_data.dart';
import 'package:tapp/models/swipe_content_item.dart';
import 'package:tapp/pages/detail.dart';
import 'package:tapp/providers/likes_provider.dart';
import 'package:tapp/theme/app_colors.dart';
import 'package:tapp/widgets/custom_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum _SwipeFeedbackType { none, nopp, tapp }

class _HomePageState extends State<HomePage> {
  static const double _bottomNavigationOverlaySpace = 110;
  final CardSwiperController _swiperController = CardSwiperController();
  _SwipeFeedbackType _feedbackType = _SwipeFeedbackType.none;
  bool _isSwipeActive = false;
  Timer? _feedbackHideTimer;

  @override
  void dispose() {
    _feedbackHideTimer?.cancel();
    _swiperController.dispose();
    super.dispose();
  }

  void _showSwipeFeedback(_SwipeFeedbackType type) {
    _feedbackHideTimer?.cancel();

    setState(() {
      _feedbackType = type;
      _isSwipeActive = type != _SwipeFeedbackType.none;
    });

    if (type == _SwipeFeedbackType.none) {
      return;
    }

    _feedbackHideTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSwipeActive = false;
      });
    });
  }

  bool _handleSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (direction.isCloseTo(CardSwiperDirection.right)) {
      context.read<LikesProvider>().addLike(swipeContentItems[previousIndex]);
    }

    final nextType = direction.isCloseTo(CardSwiperDirection.right)
        ? _SwipeFeedbackType.tapp
        : direction.isCloseTo(CardSwiperDirection.left)
        ? _SwipeFeedbackType.nopp
        : _SwipeFeedbackType.none;

    _showSwipeFeedback(nextType);

    return true;
  }

  Widget _buildMovieCard(BuildContext context, SwipeContentItem movie) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      key: Key('home_tap_${movie.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailPage(contentId: movie.id)),
        );
      },
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
                  Color(0x66000000),
                  Colors.transparent,
                  Color(0xCC000000),
                ],
                stops: [0.0, 0.46, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: bottomInset + _bottomNavigationOverlaySpace,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black87,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${movie.year} | ${movie.genres.join(' | ')}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(isOverlay: true),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CardSwiper(
            key: const Key('home_card_swiper'),
            controller: _swiperController,
            cardsCount: swipeContentItems.length,
            numberOfCardsDisplayed: 2,
            padding: EdgeInsets.zero,
            backCardOffset: const Offset(0, 36),
            isLoop: true,
            onSwipe: _handleSwipe,
            allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
              horizontal: true,
            ),
            cardBuilder:
                (
                  context,
                  index,
                  horizontalOffsetPercentage,
                  verticalOffsetPercentage,
                ) {
                  return _buildMovieCard(context, swipeContentItems[index]);
                },
          ),
          Align(
            alignment: const Alignment(0, 0.15),
            child: IgnorePointer(
              child: _SwipeFloatingFeedback(
                isVisible: _isSwipeActive,
                label: _feedbackType == _SwipeFeedbackType.tapp
                    ? 'Tapp!'
                    : 'Nopp!',
                icon: _feedbackType == _SwipeFeedbackType.tapp
                    ? Icons.favorite_rounded
                    : Icons.close_rounded,
                backgroundColor: _feedbackType == _SwipeFeedbackType.tapp
                    ? const Color(0xFFFF0A63)
                    : AppColors.brandPrimary,
                startAngleInDegrees: _feedbackType == _SwipeFeedbackType.tapp
                    ? -135
                    : -130,
                sweepAngleInDegrees: _feedbackType == _SwipeFeedbackType.tapp
                    ? 82
                    : 76,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeFloatingFeedback extends StatelessWidget {
  const _SwipeFloatingFeedback({
    required this.isVisible,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.startAngleInDegrees,
    required this.sweepAngleInDegrees,
  });

  static const double _stackSize = 156;
  static const double _buttonSize = 112;

  final bool isVisible;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final double startAngleInDegrees;
  final double sweepAngleInDegrees;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      key: const Key('home_swipe_feedback_opacity'),
      opacity: isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 210),
      curve: Curves.easeOut,
      child: AnimatedScale(
        key: const Key('home_swipe_feedback_scale'),
        scale: isVisible ? 1 : 0.84,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: _stackSize,
          height: _stackSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  excluding: !isVisible,
                  child: Semantics(
                    label: label,
                    child: CustomPaint(
                      painter: _ArcTextPainter(
                        text: label,
                        textStyle: TextStyle(
                          color: backgroundColor,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                        startAngleInDegrees: startAngleInDegrees,
                        sweepAngleInDegrees: sweepAngleInDegrees,
                        center: const Offset(
                          _stackSize / 2,
                          _stackSize - (_buttonSize / 2),
                        ),
                        radius: (_buttonSize / 2) + 15,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  width: _buttonSize,
                  height: _buttonSize,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: backgroundColor.withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 62),
                ),
              ),
            ],
          ),
        ),
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
