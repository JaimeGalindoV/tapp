import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType { series, movie }

class SwipeContentItem {
  const SwipeContentItem({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.type,
    required this.year,
    required this.genres,
    required this.providers,
    required this.rating,
    required this.overview,
    this.durationMinutes,
    this.tmdbId,
    this.providerUpdatedAt,
  });

  final String id;
  final String title;
  final String posterUrl;
  final ContentType type;
  final int year;
  final List<String> genres;
  final List<String> providers;
  final double rating;
  final String overview;
  final int? durationMinutes;
  final int? tmdbId;
  final DateTime? providerUpdatedAt;

  bool get isMovie => type == ContentType.movie;

  SwipeContentItem copyWith({
    String? id,
    String? title,
    String? posterUrl,
    ContentType? type,
    int? year,
    List<String>? genres,
    List<String>? providers,
    double? rating,
    String? overview,
    int? durationMinutes,
    int? tmdbId,
    DateTime? providerUpdatedAt,
  }) {
    return SwipeContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      type: type ?? this.type,
      year: year ?? this.year,
      genres: genres ?? this.genres,
      providers: providers ?? this.providers,
      rating: rating ?? this.rating,
      overview: overview ?? this.overview,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      tmdbId: tmdbId ?? this.tmdbId,
      providerUpdatedAt: providerUpdatedAt ?? this.providerUpdatedAt,
    );
  }

  factory SwipeContentItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return SwipeContentItem(
      id: snapshot.id,
      title: (data['title'] as String? ?? '').trim(),
      posterUrl: (data['posterUrl'] as String? ?? '').trim(),
      type: _contentTypeFromString(data['type'] as String?),
      year: (data['year'] as num?)?.toInt() ?? 0,
      genres: _stringListFromValue(data['genres']),
      providers: _stringListFromValue(data['providers']),
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      overview: (data['overview'] as String? ?? '').trim(),
      durationMinutes: (data['durationMinutes'] as num?)?.toInt(),
      tmdbId: (data['tmdbId'] as num?)?.toInt(),
      providerUpdatedAt: _dateFromValue(data['providerUpdatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'title': title,
      'posterUrl': posterUrl,
      'type': type.name,
      'year': year,
      'genres': genres,
      'providers': providers,
      'rating': rating,
      'overview': overview,
      'durationMinutes': durationMinutes,
      'tmdbId': tmdbId,
      'providerUpdatedAt': providerUpdatedAt == null
          ? null
          : Timestamp.fromDate(providerUpdatedAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static ContentType _contentTypeFromString(String? value) {
    return value == ContentType.series.name
        ? ContentType.series
        : ContentType.movie;
  }

  static List<String> _stringListFromValue(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  static DateTime? _dateFromValue(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
