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
  });

  final String id;
  final String title;
  final String posterUrl;
  final ContentType type;
  final int year;
  final List<String> genres;
  final List<String> platforms;
}
