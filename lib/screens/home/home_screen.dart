import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../models/post_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../movie/movie_detail_screen.dart';
import '../profile/profile_screen.dart';
import 'comments_sheet.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ).createShader(bounds),
                      child: Text(
                        'CineSnap',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 28,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _buildIconButton(Icons.favorite_border_rounded),
                        const SizedBox(width: 4),
                        _buildIconButton(Icons.send_outlined),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Stories row placeholder
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: index == 0
                                  ? null
                                  : const LinearGradient(
                                      colors: [AppColors.primary, AppColors.primaryLight],
                                    ),
                              border: index == 0
                                  ? Border.all(color: AppColors.surfaceLight, width: 2)
                                  : null,
                            ),
                            padding: const EdgeInsets.all(2.5),
                            child: CircleAvatar(
                              backgroundColor: AppColors.surface,
                              child: index == 0
                                  ? const Icon(Icons.add, color: AppColors.primary, size: 24)
                                  : Icon(Icons.person, color: AppColors.textMuted, size: 24),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            index == 0 ? 'Your story' : 'User $index',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Divider(color: AppColors.surfaceLight, height: 1),
            ),
            // Feed posts
            StreamBuilder<List<PostModel>>(
              stream: _firestoreService.getFeedPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyFeed(context),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildPostCard(context, posts[index]),
                    childCount: posts.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 22),
    );
  }

  Widget _buildEmptyFeed(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_filter_outlined, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No snaps yet', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Start sharing what you\'re watching!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, PostModel post) {
    final uid = _authService.currentUser?.uid ?? '';
    final isLiked = post.isLikedBy(uid);
    final timeAgo = _getTimeAgo(post.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen(userId: post.userId)),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surface,
                  backgroundImage: post.userPhotoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(post.userPhotoUrl)
                      : null,
                  child: post.userPhotoUrl.isEmpty
                      ? const Icon(Icons.person, size: 18, color: AppColors.textMuted)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userDisplayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (post.movieTitle.isNotEmpty)
                      GestureDetector(
                        onTap: post.movieImdbId.isNotEmpty
                            ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MovieDetailScreen(imdbId: post.movieImdbId),
                                ),
                              )
                            : null,
                        child: Text(
                          '🎬 ${post.movieTitle}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
        // Post Image
        AspectRatio(
          aspectRatio: 1,
          child: CachedNetworkImage(
            imageUrl: post.imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(
              color: AppColors.surface,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              ),
            ),
            errorWidget: (_, _, _) => Container(
              color: AppColors.surface,
              child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 48),
            ),
          ),
        ),
        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _firestoreService.toggleLike(post.postId, uid),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(isLiked),
                    color: isLiked ? Colors.redAccent : AppColors.textPrimary,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => _showComments(context, post),
                child: const Icon(Icons.chat_bubble_outline, color: AppColors.textPrimary, size: 23),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.send_outlined, color: AppColors.textPrimary, size: 23),
              const Spacer(),
              if (post.rating > 0) ...[
                ...List.generate(5, (i) {
                  return Icon(
                    i < post.rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                    color: AppColors.primary,
                    size: 18,
                  );
                }),
              ],
              const SizedBox(width: 8),
              const Icon(Icons.bookmark_border, color: AppColors.textPrimary, size: 24),
            ],
          ),
        ),
        // Likes count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            '${post.likeCount} likes',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
        // Caption
        if (post.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                children: [
                  TextSpan(
                    text: '${post.userDisplayName}  ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: post.caption),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        // Venue tag
        if (post.venue.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '📍 ${post.venue}',
                style: const TextStyle(fontSize: 11, color: AppColors.primary),
              ),
            ),
          ),
        // Timestamp
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Text(
            timeAgo,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  void _showComments(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(post: post),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }
}
