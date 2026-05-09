import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:tapp/models/swipe_content_item.dart';
import 'package:tapp/pages/detail.dart';
import 'package:tapp/providers/content_provider.dart';
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
  static const int _prefetchThreshold = 6;
  static const int _targetVisibleQueueSize = 18;

  final CardSwiperController _swiperController = CardSwiperController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _seenContentIds = <String>{};

  List<SwipeContentItem> _visibleQueue = const <SwipeContentItem>[];
  List<SwipeContentItem> _searchResults = const <SwipeContentItem>[];
  _SwipeFeedbackType _feedbackType = _SwipeFeedbackType.none;
  bool _isSwipeActive = false;
  bool _isInitialFeedLoading = true;
  bool _isFetchingMore = false;
  bool _isFeedExhausted = false;
  bool _isSearchLoading = false;
  int _swiperGeneration = 0;
  int _searchRequestId = 0;
  Timer? _feedbackHideTimer;
  Timer? _searchDebounceTimer;
  String _searchQuery = '';

  bool get _isSearching => _searchQuery.trim().isNotEmpty;

  List<SwipeContentItem> get _activeItems =>
      _isSearching ? _searchResults : _visibleQueue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeFeed());
    });
  }

  @override
  void dispose() {
    _feedbackHideTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
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

  Future<void> _initializeFeed() async {
    final contentProvider = context.read<ContentProvider>();
    setState(() {
      _isInitialFeedLoading = true;
      _isFeedExhausted = false;
    });

    await contentProvider.ensureMinimumContentPool(
      minimumCount: _targetVisibleQueueSize,
    );
    await _fillVisibleQueue(replaceQueue: true);
  }

  Future<void> _handleSearchChanged(String value) async {
    final query = value.trim();
    final requestId = ++_searchRequestId;

    setState(() {
      _searchQuery = query;
      _isSearchLoading = query.isNotEmpty;
      if (query.isEmpty) {
        _searchResults = const <SwipeContentItem>[];
        _swiperGeneration++;
      }
    });

    if (query.isEmpty) {
      _maybeExpandContent();
      return;
    }

    try {
      final results = await context.read<ContentProvider>().searchByTitle(query);
      if (!mounted || requestId != _searchRequestId) {
        return;
      }

      final filteredResults = results
          .where((item) => !_seenContentIds.contains(item.id))
          .toList(growable: false);

      setState(() {
        _searchResults = filteredResults;
        _isSearchLoading = false;
        _swiperGeneration++;
      });
    } catch (_) {
      if (!mounted || requestId != _searchRequestId) {
        return;
      }

      setState(() {
        _searchResults = const <SwipeContentItem>[];
        _isSearchLoading = false;
        _swiperGeneration++;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchRequestId++;
    setState(() {
      _searchQuery = '';
      _searchResults = const <SwipeContentItem>[];
      _isSearchLoading = false;
      _swiperGeneration++;
    });
    _maybeExpandContent();
  }

  bool _handleSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    final activeItems = _activeItems;
    if (previousIndex < 0 || previousIndex >= activeItems.length) {
      return false;
    }

    final likesProvider = context.read<LikesProvider>();
    final item = activeItems[previousIndex];

    setState(() {
      _seenContentIds.add(item.id);
      _visibleQueue = _visibleQueue
          .where((candidate) => candidate.id != item.id)
          .toList(growable: false);
      _searchResults = _searchResults
          .where((candidate) => candidate.id != item.id)
          .toList(growable: false);
      _swiperGeneration++;
    });

    if (direction.isCloseTo(CardSwiperDirection.right)) {
      likesProvider.addLike(item);
    } else if (direction.isCloseTo(CardSwiperDirection.left) &&
        likesProvider.isLiked(item.id)) {
      likesProvider.removeLike(item.id);
    }

    if (_isSearching) {
      if (_searchResults.isEmpty) {
        unawaited(_handleSearchChanged(_searchQuery));
      }
    } else {
      _maybeExpandContent();
    }

    final nextType = direction.isCloseTo(CardSwiperDirection.right)
        ? _SwipeFeedbackType.tapp
        : direction.isCloseTo(CardSwiperDirection.left)
        ? _SwipeFeedbackType.nopp
        : _SwipeFeedbackType.none;

    _showSwipeFeedback(nextType);
    return true;
  }

  void _maybeExpandContent() {
    if (_isFetchingMore || _isFeedExhausted || _isSearching) {
      return;
    }

    if (_visibleQueue.length <= _prefetchThreshold) {
      unawaited(_fillVisibleQueue());
    }
  }

  Future<void> _fillVisibleQueue({bool replaceQueue = false}) async {
    if (_isFetchingMore) {
      return;
    }

    final contentProvider = context.read<ContentProvider>();
    final currentQueue = replaceQueue
        ? const <SwipeContentItem>[]
        : List<SwipeContentItem>.from(_visibleQueue);
    final excludedIds = <String>{
      ..._seenContentIds,
      ...currentQueue.map((item) => item.id),
    };
    final desiredCount = replaceQueue
        ? _targetVisibleQueueSize
        : _targetVisibleQueueSize - currentQueue.length;
    if (desiredCount <= 0 && !replaceQueue) {
      return;
    }

    setState(() {
      _isFetchingMore = true;
      if (replaceQueue) {
        _isFeedExhausted = false;
      }
    });

    try {
      final newItems = await contentProvider.getUnseenCandidates(
        excludedIds: excludedIds,
        desiredCount: desiredCount <= 0 ? _targetVisibleQueueSize : desiredCount,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _visibleQueue = replaceQueue
            ? newItems
            : <SwipeContentItem>[...currentQueue, ...newItems];
        _isFeedExhausted = newItems.length <
            (replaceQueue
                ? _targetVisibleQueueSize
                : (desiredCount <= 0 ? 0 : desiredCount));
        _isFetchingMore = false;
        _isInitialFeedLoading = false;
        _swiperGeneration++;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isFetchingMore = false;
        _isInitialFeedLoading = false;
      });
    }
  }

  Future<void> _refreshCatalog() async {
    await context.read<ContentProvider>().refreshContent();
    if (!mounted) {
      return;
    }
    await context.read<ContentProvider>().ensureMinimumContentPool(
      minimumCount: _targetVisibleQueueSize,
    );
    await _fillVisibleQueue(replaceQueue: true);
    if (_isSearching) {
      await _handleSearchChanged(_searchQuery);
    }
  }

  Widget _buildMovieCard(BuildContext context, SwipeContentItem movie) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final chipColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.88);
    final chipBorderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.18);
    final chipTextColor = isDarkMode ? Colors.white : Colors.black87;

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
        children: <Widget>[
          Image.network(
            movie.posterUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF2C2C2C), Color(0xFF131313)],
                  ),
                ),
              );
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkMode
                    ? const <Color>[
                        Color(0x66000000),
                        Colors.transparent,
                        Color(0xCC000000),
                      ]
                    : const <Color>[
                        Color(0x38000000),
                        Color(0x10000000),
                        Color(0xD9000000),
                      ],
                stops: const <double>[0, 0.46, 1],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: bottomInset + _bottomNavigationOverlaySpace,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                    shadows: <Shadow>[
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Watch on',
                  key: const Key('watch_on_label'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: movie.providers
                      .map(
                        (platform) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: chipColor,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: chipBorderColor),
                          ),
                          child: Text(
                            platform,
                            style: TextStyle(
                              color: chipTextColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
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
    final contentProvider = context.watch<ContentProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        isOverlay: true,
        titleWidget: _buildSearchBar(context),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCatalog,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: _buildBody(context, contentProvider),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ContentProvider contentProvider,
  ) {
    final activeItems = _activeItems;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _buildContentLayer(context, contentProvider, activeItems),
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
    );
  }

  Widget _buildContentLayer(
    BuildContext context,
    ContentProvider contentProvider,
    List<SwipeContentItem> activeItems,
  ) {
    if (_isInitialFeedLoading && _visibleQueue.isEmpty && !_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (contentProvider.errorMessage != null &&
        _visibleQueue.isEmpty &&
        !_isSearching) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'No se pudo cargar el catálogo.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _refreshCatalog,
                child: const Text('Intentar de nuevo'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isSearching && _isSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isSearching && activeItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'No se encontraron títulos con ese nombre.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!_isSearching && _visibleQueue.isEmpty && _isFetchingMore) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Buscando más contenido...'),
          ],
        ),
      );
    }

    if (!_isSearching && _visibleQueue.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                _isFeedExhausted
                    ? 'Ya no hay más contenido nuevo por ahora.'
                    : 'Todavía no hay contenido disponible.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _refreshCatalog,
                child: const Text('Buscar mas contenido'),
              ),
            ],
          ),
        ),
      );
    }

    return CardSwiper(
      key: ValueKey<String>('home_card_swiper_$_swiperGeneration'),
      controller: _swiperController,
      cardsCount: activeItems.length,
      numberOfCardsDisplayed: activeItems.length > 1 ? 2 : 1,
      padding: EdgeInsets.zero,
      backCardOffset: const Offset(0, 36),
      isLoop: false,
      onSwipe: (previousIndex, currentIndex, direction) =>
          _handleSwipe(previousIndex, currentIndex, direction),
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
            return _buildMovieCard(context, activeItems[index]);
          },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 42,
      child: Material(
        color: colorScheme.surface.withValues(alpha: 0.92),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(21),
        child: TextField(
          key: const Key('home_search_field'),
          controller: _searchController,
          onChanged: (value) {
            _searchDebounceTimer?.cancel();
            _searchDebounceTimer = Timer(const Duration(milliseconds: 350), () {
              unawaited(_handleSearchChanged(value));
            });
          },
          textInputAction: TextInputAction.search,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Buscar por título',
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    key: const Key('home_search_clear_button'),
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(21),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(21),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(21),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          onSubmitted: (value) {
            _searchDebounceTimer?.cancel();
            unawaited(_handleSearchChanged(value));
          },
        ),
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
            children: <Widget>[
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
                    boxShadow: <BoxShadow>[
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
        .toList(growable: false);

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
