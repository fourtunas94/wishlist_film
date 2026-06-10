import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/genre.dart';
import '../services/api_service.dart';
import '../services/genre_history_service.dart';

class GenreProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Genre> _genres = [];
  List<Genre> _favoriteGenres = [];
  bool _loadingGenres = false;

  List<Genre> get genres => _genres;
  List<Genre> get favoriteGenres => _favoriteGenres;
  bool get loadingGenres => _loadingGenres;

  /// Load semua genre dari API (sekali saja)
  Future<void> loadGenres() async {
    if (_genres.isNotEmpty) return;
    _loadingGenres = true;
    notifyListeners();
    try {
      _genres = await _apiService.getGenres();
    } catch (e) {
      debugPrint('Error loading genres: $e');
    } finally {
      _loadingGenres = false;
      notifyListeners();
    }
  }

  /// Refresh daftar genre favorit dari riwayat Hive
  Future<void> refreshFavoriteGenres() async {
    if (_genres.isEmpty) await loadGenres();
    final topIds = GenreHistoryService.getTopGenres();
    _favoriteGenres =
        _genres.where((g) => topIds.contains(g.id)).toList();
    notifyListeners();
  }

  Future<List<Movie>> getMoviesByGenre(int genreId, {int page = 1}) async {
    try {
      GenreHistoryService.recordGenreOpen(genreId);
      refreshFavoriteGenres(); // update background, tidak perlu await
      return await _apiService.getMoviesByGenre(genreId, page: page);
    } catch (e) {
      debugPrint('Error loading movies by genre: $e');
      return [];
    }
  }

  /// Hapus genre dari favorit secara instan
  void removeFavoriteGenre(int genreId) {
    GenreHistoryService.removeGenre(genreId);
    _favoriteGenres.removeWhere((g) => g.id == genreId);
    notifyListeners();
  }

  // Kompatibilitas dengan kode lama
  Future<List<Genre>> getFavoriteGenres() async {
    await refreshFavoriteGenres();
    return _favoriteGenres;
  }
}