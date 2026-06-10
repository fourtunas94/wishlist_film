import 'package:hive/hive.dart';

part 'movie.g.dart';

@HiveType(typeId: 0)
class Movie {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String posterPath;
  @HiveField(3)
  final String overview;
  @HiveField(4)
  final double voteAverage;
  @HiveField(5)
  final String releaseDate;

  Movie({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.overview,
    required this.voteAverage,
    required this.releaseDate,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'] ?? 'No title',
      posterPath: json['poster_path'] ?? '',
      overview: json['overview'] ?? 'No description available.',
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      releaseDate: json['release_date'] ?? '',
    );
  }

  // Tambahan toJson untuk keperluan share
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'posterPath': posterPath,
    'overview': overview,
    'voteAverage': voteAverage,
    'releaseDate': releaseDate,
  };

  String get posterUrl {
    if (posterPath.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  String get formattedDate {
    if (releaseDate.isEmpty) return 'Unknown date';
    try {
      final date = DateTime.parse(releaseDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return releaseDate;
    }
  }
}