class MovieModel {
  final String title;
  final String year;
  final String imdbId;
  final String type;
  final String poster;
  final String plot;
  final String rated;
  final String runtime;
  final String genre;
  final String director;
  final String actors;
  final String imdbRating;

  MovieModel({
    required this.title,
    this.year = '',
    this.imdbId = '',
    this.type = 'movie',
    this.poster = '',
    this.plot = '',
    this.rated = '',
    this.runtime = '',
    this.genre = '',
    this.director = '',
    this.actors = '',
    this.imdbRating = '',
  });

  factory MovieModel.fromSearchJson(Map<String, dynamic> json) {
    return MovieModel(
      title: json['Title'] ?? '',
      year: json['Year'] ?? '',
      imdbId: json['imdbID'] ?? '',
      type: json['Type'] ?? 'movie',
      poster: json['Poster'] != 'N/A' ? (json['Poster'] ?? '') : '',
    );
  }

  factory MovieModel.fromDetailJson(Map<String, dynamic> json) {
    return MovieModel(
      title: json['Title'] ?? '',
      year: json['Year'] ?? '',
      imdbId: json['imdbID'] ?? '',
      type: json['Type'] ?? 'movie',
      poster: json['Poster'] != 'N/A' ? (json['Poster'] ?? '') : '',
      plot: json['Plot'] != 'N/A' ? (json['Plot'] ?? '') : '',
      rated: json['Rated'] != 'N/A' ? (json['Rated'] ?? '') : '',
      runtime: json['Runtime'] != 'N/A' ? (json['Runtime'] ?? '') : '',
      genre: json['Genre'] != 'N/A' ? (json['Genre'] ?? '') : '',
      director: json['Director'] != 'N/A' ? (json['Director'] ?? '') : '',
      actors: json['Actors'] != 'N/A' ? (json['Actors'] ?? '') : '',
      imdbRating: json['imdbRating'] != 'N/A' ? (json['imdbRating'] ?? '') : '',
    );
  }
}
