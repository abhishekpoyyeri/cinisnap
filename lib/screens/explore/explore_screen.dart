import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../models/movie_model.dart';
import '../../models/user_model.dart';
import '../../services/omdb_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/glassmorphic_container.dart';
import '../movie/movie_detail_screen.dart';
import '../profile/profile_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  final _omdbService = OmdbService();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  List<MovieModel> _searchResults = [];
  List<UserModel> _userResults = [];
  bool _isSearching = false;
  String _activeCategory = 'Movies';
  Timer? _debounce;

  final _categories = ['Movies', 'Series', 'Users'];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _userResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    if (_activeCategory == 'Users') {
      final users = await _firestoreService.searchUsers(query);
      setState(() {
        _userResults = users;
        _isSearching = false;
      });
    } else if (_activeCategory == 'Series') {
      final results = await _omdbService.searchSeries(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } else {
      final results = await _omdbService.searchMovies(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: GlassmorphicContainer(
                padding: EdgeInsets.zero,
                borderRadius: 14,
                child: TextField(
                  controller: _searchController,
                  onChanged: (q) {
                    if (_debounce?.isActive ?? false) _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      _search(q);
                    });
                  },
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search movies, series, or users...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _search('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            // Category chips
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isActive = cat == _activeCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _activeCategory = cat);
                        _search(_searchController.text);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isActive
                              ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight])
                              : null,
                          color: isActive ? null : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: isActive ? null : Border.all(color: AppColors.cardBorder),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isActive ? Colors.white : AppColors.textSecondary,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Search results
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _activeCategory == 'Users'
                      ? _buildUserResults()
                      : _buildMovieResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieResults() {
    if (_searchResults.isEmpty && _searchController.text.isEmpty) {
      return _buildDiscoverSection();
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              const Text('No results found', style: TextStyle(color: AppColors.textMuted)),
              if (kIsWeb) ...[
                const SizedBox(height: 24),
                Text(
                  '💡 Tip for Web: The OMDb API may be blocked by CORS.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.primary.withValues(alpha: 0.7), fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Run Chrome with --disable-web-security to fix this.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final movie = _searchResults[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MovieDetailScreen(imdbId: movie.imdbId)),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: GlassmorphicContainer(
              padding: const EdgeInsets.all(12),
              borderRadius: 14,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: movie.poster.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: movie.poster,
                            width: 60,
                            height: 85,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 60,
                            height: 85,
                            color: AppColors.surfaceLight,
                            child: const Icon(Icons.movie, color: AppColors.textMuted),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${movie.year} • ${movie.type.toUpperCase()}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserResults() {
    if (_userResults.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(
        child: Text('No users found', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    if (_userResults.isEmpty) {
      return _buildSuggestedUsers();
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.uid)),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: GlassmorphicContainer(
              padding: const EdgeInsets.all(12),
              borderRadius: 14,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.surfaceLight,
                    backgroundImage: user.photoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(user.photoUrl)
                        : null,
                    child: user.photoUrl.isEmpty
                        ? const Icon(Icons.person, color: AppColors.textMuted)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        Text(
                          '@${user.username}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiscoverSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_outlined, size: 56, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Discover', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Search for movies, series, or fellow\ncinema enthusiasts',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedUsers() {
    return FutureBuilder<List<UserModel>>(
      future: _firestoreService.getSuggestedUsers(_authService.currentUser?.uid ?? ''),
      builder: (context, snapshot) {
        final users = snapshot.data ?? [];
        if (users.isEmpty) return _buildDiscoverSection();
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            Text('Suggested for you', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...users.map((user) => GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.uid)),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: GlassmorphicContainer(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 14,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.surfaceLight,
                        child: const Icon(Icons.person, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text('@${user.username}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
          ],
        );
      },
    );
  }
}
