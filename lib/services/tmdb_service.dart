import 'dart:convert';

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

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<SwipeContentItem?> enrichContent(
    SwipeContentItem item, {
    String region = 'MX',
    String language = 'es-MX',
  }) async {
    if (!isConfigured) {
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

    final bestMatch = results.first as Map<String, dynamic>;
    final tmdbId = (bestMatch['id'] as num?)?.toInt();
    if (tmdbId == null) {
      return null;
    }

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

    final overview = (bestMatch['overview'] as String? ?? '').trim();
    final posterPath = (bestMatch['poster_path'] as String? ?? '').trim();
    final posterUrl = posterPath.isEmpty
        ? item.posterUrl
        : 'https://image.tmdb.org/t/p/w780$posterPath';

    return item.copyWith(
      tmdbId: tmdbId,
      overview: overview.isEmpty ? item.overview : overview,
      posterUrl: posterUrl,
      providers: providers.isEmpty ? item.providers : providers,
      providerUpdatedAt: DateTime.now(),
    );
  }
}
