import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String userId;
  final String userDisplayName;
  final String userPhotoUrl;
  final String username;
  final String imageUrl;
  final String caption;
  final String movieTitle;
  final String movieYear;
  final String moviePoster;
  final String movieImdbId;
  final double rating;
  final String venue; // Cinema, Home, TV, Laptop
  final List<String> likes;
  final int commentCount;
  final DateTime createdAt;

  PostModel({
    required this.postId,
    required this.userId,
    required this.userDisplayName,
    this.userPhotoUrl = '',
    this.username = '',
    required this.imageUrl,
    this.caption = '',
    this.movieTitle = '',
    this.movieYear = '',
    this.moviePoster = '',
    this.movieImdbId = '',
    this.rating = 0,
    this.venue = '',
    this.likes = const [],
    this.commentCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      userDisplayName: map['userDisplayName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'] ?? '',
      username: map['username'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'] ?? '',
      movieTitle: map['movieTitle'] ?? '',
      movieYear: map['movieYear'] ?? '',
      moviePoster: map['moviePoster'] ?? '',
      movieImdbId: map['movieImdbId'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      venue: map['venue'] ?? '',
      likes: List<String>.from(map['likes'] ?? []),
      commentCount: map['commentCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userPhotoUrl': userPhotoUrl,
      'username': username,
      'imageUrl': imageUrl,
      'caption': caption,
      'movieTitle': movieTitle,
      'movieYear': movieYear,
      'moviePoster': moviePoster,
      'movieImdbId': movieImdbId,
      'rating': rating,
      'venue': venue,
      'likes': likes,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool isLikedBy(String userId) => likes.contains(userId);
  int get likeCount => likes.length;
}
