import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:tapp/models/swipe_content_item.dart';

class TmdbService {
  TmdbService({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKey =
          apiKey ??
          dotenv.env['TMDB_API_KEY']?.trim() ??
          const String.fromEnvironment('TMDB_API_KEY');

  final http.Client _client;
  final String _apiKey;
  final math.Random _random = math.Random();

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<List<SwipeContentItem>> searchByTitle(
    String query, {
    String region = 'MX',
    String language = 'es-MX',
  }) async {
    final normalizedQuery = query.trim();
    if (!isConfigured || normalizedQuery.isEmpty) {
      return const <SwipeContentItem>[];
    }

    final results = await Future.wait(<Future<List<SwipeContentItem>>>[
      _searchItems(
        type: ContentType.movie,
        query: normalizedQuery,
        region: region,
        language: language,
      ),
      _searchItems(
        type: ContentType.series,
        query: normalizedQuery,
        region: region,
        language: language,
      ),
    ]);

    final merged = results.expand((items) => items).toList(growable: true);
    merged.sort((a, b) {
      final aStarts = a.title.toLowerCase().startsWith(normalizedQuery.toLowerCase());
      final bStarts = b.title.toLowerCase().startsWith(normalizedQuery.toLowerCase());
      if (aStarts != bStarts) {
        return aStarts ? -1 : 1;
      }
      final ratingCompare = b.rating.compareTo(a.rating);
      if (ratingCompare != 0) {
        return ratingCompare;
      }
      return b.year.compareTo(a.year);
    });

    return merged;
  }

  Future<List<SwipeContentItem>> fetchRandomDiscoverBatch({
    int moviePages = 2,
    int seriesPages = 2,
    String region = 'MX',
    String language = 'es-MX',
  }) async {
    if (!isConfigured) {
      return const <SwipeContentItem>[];
    }

    final futures = <Future<List<SwipeContentItem>>>[];
    for (var index = 0; index < moviePages; index++) {
      futures.add(
        _discoverItems(
          type: ContentType.movie,
          region: region,
          language: language,
          page: _randomPage(),
        ),
      );
    }
    for (var index = 0; index < seriesPages; index++) {
      futures.add(
        _discoverItems(
          type: ContentType.series,
          region: region,
          language: language,
          page: _randomPage(),
        ),
      );
    }

    final batches = await Future.wait(futures);
    final merged = batches.expand((batch) => batch).toList(growable: true);
    merged.shuffle(_random);
    return merged;
  }

  Future<SwipeContentItem?> enrichContent(
    SwipeContentItem item, {
    String region = 'MX',
    String language = 'es-MX',
  }) async {
    if (!isConfigured) {
      return null;
    }

    final bestMatch = await _resolveBestMatch(
      item,
      language: language,
    );
    final tmdbId = item.tmdbId ?? (bestMatch?['id'] as num?)?.toInt();
    if (tmdbId == null) {
      return null;
    }

    final detailPath = item.isMovie ? '/3/movie/$tmdbId' : '/3/tv/$tmdbId';
    final detailUri = Uri.https(
      'api.themoviedb.org',
      detailPath,
      <String, String>{'api_key': _apiKey, 'language': language},
    );
    final detailResponse = await _client.get(detailUri);
    final detailData = detailResponse.statusCode == 200
        ? jsonDecode(detailResponse.body) as Map<String, dynamic>
        : null;

    final providerPath = item.isMovie
        ? '/3/movie/$tmdbId/watch/providers'
        : '/3/tv/$tmdbId/watch/providers';
    final providerUri = Uri.https(
      'api.themoviedb.org',
      providerPath,
      <String, String>{'api_key': _apiKey},
    );
    final providerResponse = await _client.get(providerUri);

    final providers = <String>[];
    if (providerResponse.statusCode == 200) {
      final providerData =
          jsonDecode(providerResponse.body) as Map<String, dynamic>;
      final resultsMap = providerData['results'] as Map<String, dynamic>?;
      final regionData = resultsMap?[region] as Map<String, dynamic>?;
      final offerLists = <Object?>[
        regionData?['flatrate'],
        regionData?['rent'],
        regionData?['buy'],
      ];

      for (final offerList in offerLists) {
        if (offerList is! List) {
          continue;
        }
        for (final offer in offerList) {
          if (offer is! Map<String, dynamic>) {
            continue;
          }
          final providerName = (offer['provider_name'] as String? ?? '').trim();
          if (providerName.isEmpty || providers.contains(providerName)) {
            continue;
          }
          providers.add(providerName);
        }
      }
    }

    final overview =
        (detailData?['overview'] as String? ??
                bestMatch?['overview'] as String? ??
                '')
            .trim();
    final posterPath =
        (detailData?['poster_path'] as String? ??
                bestMatch?['poster_path'] as String? ??
                '')
            .trim();
    final posterUrl = posterPath.isEmpty
        ? item.posterUrl
        : 'https://image.tmdb.org/t/p/w780$posterPath';
    final runtimeMinutes = item.isMovie
        ? _positiveInt(detailData?['runtime']) ?? item.durationMinutes
        : item.durationMinutes;
    final seasonCount = item.isMovie
        ? item.seasonCount
        : _positiveInt(detailData?['number_of_seasons']) ?? item.seasonCount;

    return item.copyWith(
      tmdbId: tmdbId,
      overview: overview.isEmpty ? item.overview : overview,
      posterUrl: posterUrl,
      durationMinutes: runtimeMinutes,
      seasonCount: seasonCount,
      providers: providers.isEmpty ? item.providers : providers,
      providerUpdatedAt: DateTime.now(),
    );
  }

  Future<Map<String, dynamic>?> _resolveBestMatch(
    SwipeContentItem item, {
    required String language,
  }) async {
    if (item.tmdbId != null) {
      return null;
    }

    final searchPath = item.isMovie ? '/3/search/movie' : '/3/search/tv';
    final searchParams = <String, String>{
      'api_key': _apiKey,
      'query': item.title,
      'language': language,
      if (item.isMovie) 'year': item.year.toString(),
      if (!item.isMovie) 'first_air_date_year': item.year.toString(),
    };
    final searchUri = Uri.https('api.themoviedb.org', searchPath, searchParams);
    final searchResponse = await _client.get(searchUri);

    if (searchResponse.statusCode != 200) {
      return null;
    }

    final searchData = jsonDecode(searchResponse.body) as Map<String, dynamic>;
    final results = searchData['results'];
    if (results is! List || results.isEmpty) {
      return null;
    }

    return results.first as Map<String, dynamic>;
  }

  Future<List<SwipeContentItem>> _discoverItems({
    required ContentType type,
    required String region,
    required String language,
    required int page,
  }) async {
    final path = type == ContentType.movie
        ? '/3/discover/movie'
        : '/3/discover/tv';
    final params = <String, String>{
      'api_key': _apiKey,
      'language': language,
      'region': region,
      'page': page.toString(),
      'sort_by': 'popularity.desc',
      'include_adult': 'false',
      'vote_count.gte': '50',
    };

    final uri = Uri.https('api.themoviedb.org', path, params);
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      return const <SwipeContentItem>[];
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'];
    if (results is! List) {
      return const <SwipeContentItem>[];
    }

    final items = <SwipeContentItem>[];
    for (final entry in results) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final item = _mapDiscoverResult(entry, type: type);
      if (item != null) {
        items.add(item);
      }
    }
    return items;
  }

  Future<List<SwipeContentItem>> _searchItems({
    required ContentType type,
    required String query,
    required String region,
    required String language,
  }) async {
    final path = type == ContentType.movie ? '/3/search/movie' : '/3/search/tv';
    final params = <String, String>{
      'api_key': _apiKey,
      'language': language,
      'region': region,
      'query': query,
      'page': '1',
      'include_adult': 'false',
    };

    final uri = Uri.https('api.themoviedb.org', path, params);
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      return const <SwipeContentItem>[];
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'];
    if (results is! List) {
      return const <SwipeContentItem>[];
    }

    final items = <SwipeContentItem>[];
    for (final entry in results.take(10)) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final item = _mapDiscoverResult(entry, type: type);
      if (item != null) {
        items.add(item);
      }
    }
    return items;
  }

  SwipeContentItem? _mapDiscoverResult(
    Map<String, dynamic> data, {
    required ContentType type,
  }) {
    final tmdbId = (data['id'] as num?)?.toInt();
    if (tmdbId == null) {
      return null;
    }

    final rawTitle = (type == ContentType.movie
            ? data['title']
            : data['name']) as String? ??
        '';
    final title = rawTitle.trim();
    if (title.isEmpty) {
      return null;
    }

    final posterPath = (data['poster_path'] as String? ?? '').trim();
    if (posterPath.isEmpty) {
      return null;
    }

    final dateValue = (type == ContentType.movie
            ? data['release_date']
            : data['first_air_date']) as String? ??
        '';
    final year = _parseYear(dateValue);
    if (year <= 0) {
      return null;
    }

    final genreIds = (data['genre_ids'] as List?)
            ?.map((value) => (value as num?)?.toInt())
            .whereType<int>()
            .toList(growable: false) ??
        const <int>[];
    final genres = _resolveGenres(type, genreIds);
    final overview = (data['overview'] as String? ?? '').trim();
    final rating = ((data['vote_average'] as num?)?.toDouble() ?? 0) / 2;

    return SwipeContentItem(
      id: _buildContentId(type, tmdbId),
      title: title,
      posterUrl: 'https://image.tmdb.org/t/p/w780$posterPath',
      type: type,
      year: year,
      genres: genres.isEmpty ? const <String>['General'] : genres,
      providers: const <String>[],
      rating: rating.clamp(0, 5).toDouble(),
      overview: overview.isEmpty
          ? 'Sin descripción disponible por el momento.'
          : overview,
      tmdbId: tmdbId,
      providerUpdatedAt: null,
    );
  }

  static String _buildContentId(ContentType type, int tmdbId) {
    final prefix = type == ContentType.movie ? 'm' : 's';
    return '${prefix}_tmdb_$tmdbId';
  }

  int _randomPage() {
    return 1 + _random.nextInt(60);
  }

  static int _parseYear(String value) {
    if (value.length < 4) {
      return 0;
    }
    return int.tryParse(value.substring(0, 4)) ?? 0;
  }

  static List<String> _resolveGenres(ContentType type, List<int> ids) {
    final genreMap = type == ContentType.movie
        ? _movieGenresById
        : _seriesGenresById;
    return ids
        .map((id) => genreMap[id]?.trim() ?? '')
        .where((genre) => genre.isNotEmpty)
        .take(3)
        .toList(growable: false);
  }

  static int? _positiveInt(Object? value) {
    final parsed = (value as num?)?.toInt();
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }
}

const Map<int, String> _movieGenresById = <int, String>{
  28: 'Action',
  12: 'Adventure',
  16: 'Animation',
  35: 'Comedy',
  80: 'Crime',
  99: 'Documentary',
  18: 'Drama',
  10751: 'Family',
  14: 'Fantasy',
  36: 'History',
  27: 'Horror',
  10402: 'Music',
  9648: 'Mystery',
  10749: 'Romance',
  878: 'Sci-Fi',
  10770: 'TV Movie',
  53: 'Thriller',
  10752: 'War',
  37: 'Western',
};

const Map<int, String> _seriesGenresById = <int, String>{
  10759: 'Action',
  16: 'Animation',
  35: 'Comedy',
  80: 'Crime',
  99: 'Documentary',
  18: 'Drama',
  10751: 'Family',
  10762: 'Kids',
  9648: 'Mystery',
  10763: 'News',
  10764: 'Reality',
  10765: 'Sci-Fi',
  10766: 'Soap',
  10767: 'Talk Show',
  10768: 'War',
  37: 'Western',
};
