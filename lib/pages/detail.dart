import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tapp/models/swipe_content_item.dart';
import 'package:tapp/models/user_review.dart';
import 'package:tapp/providers/content_provider.dart';
import 'package:tapp/providers/reviews_provider.dart';
import 'package:tapp/providers/user_profile_provider.dart';
import 'package:tapp/widgets/custom_app_bar.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.contentId});

  final String contentId;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late final TextEditingController _reviewController;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _loadedReviewForUserId;

  @override
  void initState() {
    super.initState();
    _reviewController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentProvider>().ensureContentAvailable(widget.contentId);
      _loadCurrentUserReview();
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserReview() async {
    final user = _currentUserSafe;
    if (user == null) {
      return;
    }

    final review = await context
        .read<ReviewsProvider>()
        .getUserReviewForContent(contentId: widget.contentId, userId: user.uid);
    if (!mounted) {
      return;
    }

    setState(() {
      _loadedReviewForUserId = user.uid;
      _reviewController.text = review?.text ?? '';
    });
  }

  Future<void> _saveReview(User user) async {
    final text = _reviewController.text.trim();
    if (text.isEmpty) {
      _showMessage('Escribe una reseña antes de guardar.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await context.read<ReviewsProvider>().upsertReview(
        contentId: widget.contentId,
        user: user,
        text: text,
      );
      if (!mounted) {
        return;
      }
      await context.read<UserProfileProvider>().refreshStats(user);
      _showMessage('Reseña guardada.');
    } catch (_) {
      if (mounted) {
        _showMessage('No se pudo guardar la reseña.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _loadedReviewForUserId = user.uid;
        });
      }
    }
  }

  Future<void> _deleteReview(User user) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await context.read<ReviewsProvider>().deleteReview(
        contentId: widget.contentId,
        userId: user.uid,
      );
      if (!mounted) {
        return;
      }
      _reviewController.clear();
      await context.read<UserProfileProvider>().refreshStats(user);
      _showMessage('Reseña eliminada.');
    } catch (_) {
      if (mounted) {
        _showMessage('No se pudo eliminar la reseña.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _loadedReviewForUserId = user.uid;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final item = context.watch<ContentProvider>().getById(widget.contentId);
    if (item == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final reviewsProvider = context.watch<ReviewsProvider>();
    return StreamBuilder<List<UserReview>>(
      stream: reviewsProvider.watchReviews(widget.contentId),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const <UserReview>[];
        _syncCurrentUserText(reviews);
        return _buildScaffold(context, item, reviews);
      },
    );
  }

  void _syncCurrentUserText(List<UserReview> reviews) {
    final user = _currentUserSafe;
    if (user == null || _loadedReviewForUserId == user.uid) {
      return;
    }

    for (final review in reviews) {
      if (review.userId == user.uid) {
        _reviewController.text = review.text;
        _loadedReviewForUserId = user.uid;
        return;
      }
    }
  }

  Widget _buildScaffold(
    BuildContext context,
    SwipeContentItem item,
    List<UserReview> reviews,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = _currentUserSafe;
    final currentUserReview = user == null
        ? null
        : _findCurrentUserReview(reviews, user.uid);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        showBackButton: true,
        logoCentered: true,
        showConfigButton: true,
        isOverlay: true,
      ),
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ContentProvider>().refreshContent();
          await _loadCurrentUserReview();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.network(
                    item.posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
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
                            ? const <Color>[
                                Color(0x12000000),
                                Color(0x520E0E11),
                                Color(0xFF0E0E11),
                                Color(0xFF0E0E11),
                              ]
                            : const <Color>[
                                Color(0x12000000),
                                Color(0x3FFFFFFF),
                                Color(0xFFF6F6F8),
                                Color(0xFFF6F6F8),
                              ],
                        stops: const <double>[0, 0.72, 0.96, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
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
                          '${item.type == ContentType.movie ? 'Pelicula' : 'Serie'} | ${item.year} | ${item.genres.join(' | ')}',
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
                children: <Widget>[
                  Text(
                    item.overview,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 20,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: <Widget>[
                      ...List<Widget>.generate(5, (index) {
                        final star = index < item.rating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded;
                        return Icon(
                          star,
                          color: colorScheme.onSurface,
                          size: 31,
                        );
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
                        reviews.length.toString(),
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
                          padding: const EdgeInsets.all(4),
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
                    children: item.providers
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
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 26),
                  if (item.type == ContentType.movie &&
                      item.durationMinutes != null)
                    Text(
                      'Duración: ${item.durationMinutes} min',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 32),
                  Text(
                    'Tu reseña',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('detail_review_field'),
                    controller: _reviewController,
                    minLines: 3,
                    maxLines: 5,
                    enabled: user != null,
                    decoration: InputDecoration(
                      hintText: user == null
                          ? 'Inicia sesión para escribir una reseña.'
                          : 'Escribe tu opinión sobre este título',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton.icon(
                          key: const Key('detail_save_review_button'),
                          onPressed: user == null || _isSaving
                              ? null
                              : () => _saveReview(user),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            currentUserReview == null
                                ? 'Crear reseña'
                                : 'Guardar cambios',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('detail_delete_review_button'),
                          onPressed:
                              user == null ||
                                  currentUserReview == null ||
                                  _isDeleting
                              ? null
                              : () => _deleteReview(user),
                          icon: _isDeleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.delete_outline),
                          label: const Text('Eliminar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Reseñas recientes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (reviews.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Text(
                        'Todavía no hay reseñas para este título.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    )
                  else
                    ...reviews.map(
                      (review) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                review.userDisplayName,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                review.text,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareContent(SwipeContentItem item) async {
    final typeLabel = item.type == ContentType.movie ? 'pelicula' : 'serie';
    final message =
        'Te recomiendo $typeLabel: ${item.title} (${item.year})\n'
        'Generos: ${item.genres.join(', ')}\n'
        'Calificacion: ${item.rating.toStringAsFixed(1)}\n'
        'Disponible en: ${item.providers.join(', ')}\n\n'
        'Visto en Tapp.';

    await SharePlus.instance.share(
      ShareParams(text: message, subject: 'Recomendacion: ${item.title}'),
    );
  }

  UserReview? _findCurrentUserReview(List<UserReview> reviews, String userId) {
    for (final review in reviews) {
      if (review.userId == userId) {
        return review;
      }
    }
    return null;
  }

  User? get _currentUserSafe {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }
}
