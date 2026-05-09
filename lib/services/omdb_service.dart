import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';

class OmdbService {
  static const String _apiKey = '32397430';
  static const String _baseUrl = 'https://www.omdbapi.com/';

  /// On web, OMDb may be subject to CORS restrictions.
  /// Use a proxy to bypass them in development.
  String _buildUrl(Map<String, String> params) {
    params['apikey'] = _apiKey;
    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    if (kIsWeb) {
      // Use allorigins JSON wrapper to bypass CORS in web
      final targetUrl = '$_baseUrl?$queryString';
      return 'https://api.allorigins.win/get?url=${Uri.encodeComponent(targetUrl)}';
    }
    return '$_baseUrl?$queryString';
  }

  dynamic _decodeResponse(http.Response response) {
    final data = json.decode(response.body);
    if (kIsWeb) {
      // AllOrigins returns the actual response in the 'contents' field as a string
      return json.decode(data['contents']);
    }
    return data;
  }

  Future<List<MovieModel>> searchMovies(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final url = _buildUrl({'s': query, 'type': 'movie'});
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = _decodeResponse(response);
        if (data['Response'] == 'True' && data['Search'] != null) {
          return (data['Search'] as List)
              .map((item) => MovieModel.fromSearchJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrintOmdb('searchMovies error: $e');
      return [];
    }
  }

  Future<List<MovieModel>> searchSeries(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final url = _buildUrl({'s': query, 'type': 'series'});
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = _decodeResponse(response);
        if (data['Response'] == 'True' && data['Search'] != null) {
          return (data['Search'] as List)
              .map((item) => MovieModel.fromSearchJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrintOmdb('searchSeries error: $e');
      return [];
    }
  }

  Future<MovieModel?> getMovieDetails(String imdbId) async {
    try {
      final url = _buildUrl({'i': imdbId, 'plot': 'full'});
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = _decodeResponse(response);
        if (data['Response'] == 'True') {
          return MovieModel.fromDetailJson(data);
        }
      }
      return null;
    } catch (e) {
      debugPrintOmdb('getMovieDetails error: $e');
      return null;
    }
  }

  Future<List<MovieModel>> searchAll(String query) async {
    if (query.isEmpty) return [];
    
    final movies = await searchMovies(query);
    final series = await searchSeries(query);
    return [...movies, ...series];
  }

  void debugPrintOmdb(String message) {
    // ignore: avoid_print
    print('[OmdbService] $message');
  }
}
