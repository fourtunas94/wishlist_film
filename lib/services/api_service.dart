import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../models/genre.dart';

class ApiService {
  // GANTI DENGAN API KEY ANDA
  static const String apiKey = 'd3690d4b073ef2323851d347b15316e7';
  static const String baseUrl = 'https://api.themoviedb.org/3';

  // ========== MOVIES ==========
  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movie/popular?api_key=$apiKey&page=$page'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => Movie.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load popular movies');
    }
  }

  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    if (query.isEmpty) return [];
    final response = await http.get(
      Uri.parse('$baseUrl/search/movie?api_key=$apiKey&query=$query&page=$page'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => Movie.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to search movies');
    }
  }

  Future<Movie> getMovieDetail(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movie/$id?api_key=$apiKey'),
    );
    if (response.statusCode == 200) {
      return Movie.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load movie details');
    }
  }

  /// Mengembalikan detail film + credits (cast & crew) + production companies
  /// sekaligus dalam 1 request menggunakan append_to_response
  Future<Map<String, dynamic>> getMovieDetailsWithCredits(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movie/$id?api_key=$apiKey&append_to_response=credits'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load movie details with credits');
    }
  }

  // ========== GENRES ==========
  Future<List<Genre>> getGenres() async {
    final response = await http.get(
      Uri.parse('$baseUrl/genre/movie/list?api_key=$apiKey'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['genres'] as List)
          .map((json) => Genre.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load genres');
    }
  }

  Future<List<Movie>> getMoviesByGenre(int genreId, {int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/discover/movie?api_key=$apiKey&with_genres=$genreId&page=$page'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => Movie.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load movies by genre');
    }
  }

  // ========== SIMILAR MOVIES ==========
  Future<List<Movie>> getSimilarMovies(int movieId, {int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movie/$movieId/similar?api_key=$apiKey&page=$page'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => Movie.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load similar movies');
    }
  }

  // ========== AUTOCOMPLETE (PERSON / COMPANY) ==========
  Future<List<Map<String, dynamic>>> searchPersonAutocomplete(String query) async {
    if (query.isEmpty || query.length < 2) return [];
    final response = await http.get(
      Uri.parse('$baseUrl/search/person?api_key=$apiKey&query=$query'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((person) {
        return {
          'id': person['id'],
          'name': person['name'],
        };
      }).toList();
    } else {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchCompanyAutocomplete(String query) async {
    if (query.isEmpty || query.length < 2) return [];
    final response = await http.get(
      Uri.parse('$baseUrl/search/company?api_key=$apiKey&query=$query'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((company) {
        return {
          'id': company['id'],
          'name': company['name'],
        };
      }).toList();
    } else {
      return [];
    }
  }

  // ========== DISCOVER MOVIES WITH FILTERS (Aktor, Studio, Tahun) ==========
  Future<List<Movie>> discoverMoviesWithFilters({
    int? minYear,
    int? maxYear,
    int? withCastId,       // ID aktor/pemeran
    int? withCompanyId,    // ID studio
    int page = 1,
  }) async {
    final Map<String, String> params = {
      'api_key': apiKey,
      'page': page.toString(),
    };

    // Rentang tahun rilis
    if (minYear != null && maxYear != null) {
      params['primary_release_date.gte'] = '$minYear-01-01';
      params['primary_release_date.lte'] = '$maxYear-12-31';
    } else if (minYear != null) {
      params['primary_release_date.gte'] = '$minYear-01-01';
    } else if (maxYear != null) {
      params['primary_release_date.lte'] = '$maxYear-12-31';
    }

    // Filter berdasarkan pemeran (more accurate than with_people)
    if (withCastId != null) {
      params['with_cast'] = withCastId.toString();
    }

    // Filter berdasarkan perusahaan produksi (studio)
    if (withCompanyId != null) {
      params['with_companies'] = withCompanyId.toString();
    }

    final uri = Uri.parse('$baseUrl/discover/movie').replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => Movie.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to discover movies: ${response.statusCode}');
    }
  }
}