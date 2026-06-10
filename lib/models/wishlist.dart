import 'package:hive/hive.dart';
import 'movie.dart';

part 'wishlist.g.dart';

@HiveType(typeId: 2)
class ShareableWishlist {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final List<Movie> movies;

  ShareableWishlist({
    required this.id,
    required this.name,
    required this.movies,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'movies': movies.map((m) => m.toJson()).toList(),
  };

  factory ShareableWishlist.fromJson(Map<String, dynamic> json) {
    return ShareableWishlist(
      id: json['id'],
      name: json['name'],
      movies: (json['movies'] as List)
          .map((m) => Movie.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Ekstensi Movie untuk toJson (karena Movie sebelumnya tidak punya toJson)
extension MovieJson on Movie {
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'posterPath': posterPath,
    'overview': overview,
    'voteAverage': voteAverage,
    'releaseDate': releaseDate,
  };
}