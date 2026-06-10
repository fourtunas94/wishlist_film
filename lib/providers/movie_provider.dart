import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/api_service.dart';

class MovieProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  final List<Movie> _popularMovies = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  List<Movie> get popularMovies => _popularMovies;
  bool get isLoading => _isLoading;

  Future<void> loadPopularMovies({bool refresh = false}) async {
    if (refresh) {
      _popularMovies.clear();
      _currentPage = 1;
      _hasMore = true;
    }
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final movies = await _apiService.getPopularMovies(page: _currentPage);
      if (movies.isNotEmpty) {
        _popularMovies.addAll(movies);
        _currentPage++;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      print('Error loading movies: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<Movie>> searchMovies(String query) async {
    if (query.isEmpty) return [];
    try {
      return await _apiService.searchMovies(query);
    } catch (e) {
      print('Error searching: $e');
      return [];
    }
  }
}