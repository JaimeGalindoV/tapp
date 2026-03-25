enum ContentType {
  series,
  movie,
}

class SwipeContentItem {
  const SwipeContentItem({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.type,
    required this.year,
    required this.genres,
    required this.platforms,
    required this.rating,
    required this.commentCount,
    this.durationMinutes,
  });

  final String id;
  final String title;
  final String posterUrl;
  final ContentType type;
  final int year;
  final List<String> genres;
  final List<String> platforms;
  final double rating;
  final int commentCount;
  final int? durationMinutes;
}
