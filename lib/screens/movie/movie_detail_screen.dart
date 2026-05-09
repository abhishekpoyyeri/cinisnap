import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../models/movie_model.dart';
import '../../models/post_model.dart';
import '../../services/omdb_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/glassmorphic_container.dart';

class MovieDetailScreen extends StatefulWidget {
  final String imdbId;
  const MovieDetailScreen({super.key, required this.imdbId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final _omdbService = OmdbService();
  final _firestoreService = FirestoreService();
  MovieModel? _movie;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMovie();
  }

  Future<void> _loadMovie() async {
    final movie = await _omdbService.getMovieDetails(widget.imdbId);
    setState(() {
      _movie = movie;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_movie == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Movie not found', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero section
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred backdrop
                  if (_movie!.poster.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: _movie!.poster,
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.5),
                      colorBlendMode: BlendMode.darken,
                    ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(color: Colors.black.withValues(alpha: 0.4)),
                  ),
                  // Content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Sharp poster
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _movie!.poster.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: _movie!.poster,
                                      width: 130,
                                      height: 195,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 130,
                                      height: 195,
                                      color: AppColors.surfaceLight,
                                      child: const Icon(Icons.movie, color: AppColors.textMuted, size: 48),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          // Movie info
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _movie!.title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_movie!.year} • ${_movie!.runtime}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                // Genre badges
                                if (_movie!.genre.isNotEmpty)
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: _movie!.genre.split(', ').take(3).map((g) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          g,
                                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                const SizedBox(height: 8),
                                // Rating
                                if (_movie!.imdbRating.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: AppColors.primary, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        _movie!.imdbRating,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const Text(
                                        ' / 10',
                                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Synopsis
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Director and Cast
                  if (_movie!.director.isNotEmpty) ...[
                    _buildInfoRow('Director', _movie!.director),
                    const SizedBox(height: 8),
                  ],
                  if (_movie!.actors.isNotEmpty) ...[
                    _buildInfoRow('Cast', _movie!.actors),
                    const SizedBox(height: 16),
                  ],
                  // Synopsis
                  if (_movie!.plot.isNotEmpty) ...[
                    Text('Synopsis', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    GlassmorphicContainer(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 14,
                      child: Text(
                        _movie!.plot,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Community snaps section
                  Text('Community Snaps', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'See how others are watching this',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          // Community posts grid
          StreamBuilder<List<PostModel>>(
            stream: _firestoreService.getMoviePosts(widget.imdbId),
            builder: (context, snapshot) {
              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.textMuted.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          const Text('No snaps for this movie yet', style: TextStyle(color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          const Text('Be the first to share!', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = posts[index];
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: post.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(color: AppColors.surface),
                          ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '@${post.username}',
                                style: const TextStyle(color: Colors.white, fontSize: 9),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    childCount: posts.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      // Floating "Snap this movie" button
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.pop(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
          label: const Text(
            'Snap this movie',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}
