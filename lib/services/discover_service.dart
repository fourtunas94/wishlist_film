import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import 'api_service.dart';

class DiscoverService {
  static const String apiKey = ApiService.apiKey;
  static const String baseUrl = ApiService.baseUrl;

  Future<List<Movie>> discoverMovies({
    String? withPeople,
    String? year,
    String? withCompanies,
    int page = 1,
  }) async {
    final uri = Uri.parse('$baseUrl/discover/movie').replace(queryParameters: {
      'api_key': apiKey,
      'page': page.toString(),
      if (withPeople != null && withPeople.isNotEmpty) 'with_people': withPeople,
      if (year != null && year.isNotEmpty) 'primary_release_year': year,
      if (withCompanies != null && withCompanies.isNotEmpty) 'with_companies': withCompanies,
    });
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => Movie.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to discover movies');
    }
  }

  Future<String?> searchPersonId(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search/person?api_key=$apiKey&query=$query'),
    );
    if (response.statusCode == 200) {
      final results = json.decode(response.body)['results'];
      if (results.isNotEmpty) return results[0]['id'].toString();
    }
    return null;
  }

  Future<String?> searchCompanyId(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search/company?api_key=$apiKey&query=$query'),
    );
    if (response.statusCode == 200) {
      final results = json.decode(response.body)['results'];
      if (results.isNotEmpty) return results[0]['id'].toString();
    }
    return null;
  }
}