import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../models/post_model.dart';
import '../../models/movie_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/omdb_service.dart';
import '../../widgets/glassmorphic_container.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _movieSearchController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  final _omdbService = OmdbService();
  
  XFile? _selectedImage;
  MovieModel? _selectedMovie;
  List<MovieModel> _movieSuggestions = [];
  bool _isPosting = false;
  double _rating = 0;
  String _venue = '';
  final _venues = ['Cinema', 'Home', 'TV', 'Laptop'];

  @override
  void dispose() {
    _captionController.dispose();
    _movieSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1200);
    if (picked != null) {
      setState(() => _selectedImage = picked);
    }
  }

  Future<void> _searchMovies(String query) async {
    if (query.length < 2) {
      setState(() => _movieSuggestions = []);
      return;
    }
    final results = await _omdbService.searchAll(query);
    setState(() {
      _movieSuggestions = results;
    });
  }

  Future<void> _sharePost() async {
    if (_selectedImage == null) {
      _showSnackBar('Please select an image');
      return;
    }
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isPosting = true);
    try {
      final imageUrl = await _storageService.uploadPostImage(_selectedImage!, user.uid);
      final post = PostModel(
        postId: const Uuid().v4(),
        userId: user.uid,
        userDisplayName: user.displayName ?? 'User',
        userPhotoUrl: user.photoURL ?? '',
        username: user.displayName?.toLowerCase().replaceAll(' ', '_') ?? '',
        imageUrl: imageUrl,
        caption: _captionController.text.trim(),
        movieTitle: _selectedMovie?.title ?? '',
        movieYear: _selectedMovie?.year ?? '',
        moviePoster: _selectedMovie?.poster ?? '',
        movieImdbId: _selectedMovie?.imdbId ?? '',
        rating: _rating,
        venue: _venue,
      );
      await _firestoreService.createPost(post);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Snap shared! 🎬'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Failed to share snap. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: isError ? AppColors.error : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Snap'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isPosting ? null : _sharePost,
              child: _isPosting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                    )
                  : const Text(
                      'Share',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            GestureDetector(
              onTap: () => _showImagePicker(),
              child: GlassmorphicContainer(
                padding: EdgeInsets.zero,
                borderRadius: 16,
                borderColor: _selectedImage != null
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.cardBorder,
                width: double.infinity,
                height: 320,
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: kIsWeb 
                          ? Image.network(_selectedImage!.path, fit: BoxFit.cover, width: double.infinity, height: 320)
                          : Image.file(File(_selectedImage!.path), fit: BoxFit.cover, width: double.infinity, height: 320),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.1),
                            ),
                            child: const Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tap to capture your screen',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Take a photo of what you\'re watching',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // Caption
            GlassmorphicContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: 14,
              child: TextField(
                controller: _captionController,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'What are you watching? Share your thoughts...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Movie tag search
            Text('Tag a Movie or Series', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            GlassmorphicContainer(
              padding: EdgeInsets.zero,
              borderRadius: 14,
              child: TextField(
                controller: _movieSearchController,
                onChanged: _searchMovies,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search for a movie or series...',
                  prefixIcon: const Icon(Icons.movie_outlined, color: AppColors.primary, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  suffixIcon: _selectedMovie != null
                      ? IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                          onPressed: () {
                            setState(() {
                              _selectedMovie = null;
                              _movieSearchController.clear();
                              _movieSuggestions = [];
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
            // Selected movie chip
            if (_selectedMovie != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primary.withValues(alpha: 0.08)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_movies, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedMovie!.title} (${_selectedMovie!.year})',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            // Movie suggestions
            if (_movieSuggestions.isNotEmpty && _selectedMovie == null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 200),
                child: GlassmorphicContainer(
                  padding: EdgeInsets.zero,
                  borderRadius: 12,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _movieSuggestions.length,
                    itemBuilder: (context, index) {
                      final movie = _movieSuggestions[index];
                      return ListTile(
                        dense: true,
                        leading: movie.poster.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CachedNetworkImage(
                                  imageUrl: movie.poster,
                                  width: 35,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.movie, color: AppColors.textMuted, size: 24),
                        title: Text(
                          movie.title,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${movie.year} • ${movie.type}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedMovie = movie;
                            _movieSearchController.text = movie.title;
                            _movieSuggestions = [];
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 20),
            // Venue chips
            Text('Where are you watching?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _venues.map((v) {
                final selected = _venue == v;
                final icons = {
                  'Cinema': Icons.theaters,
                  'Home': Icons.home_outlined,
                  'TV': Icons.tv,
                  'Laptop': Icons.laptop_mac,
                };
                return GestureDetector(
                  onTap: () => setState(() => _venue = selected ? '' : v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(
                              colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primary.withValues(alpha: 0.08)],
                            )
                          : null,
                      color: selected ? null : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.primary.withValues(alpha: 0.5) : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icons[v], size: 16, color: selected ? AppColors.primary : AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          v,
                          style: TextStyle(
                            color: selected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Rating
            Text('Rate it', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1.0),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Camera', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Take a new photo', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: const Text('Gallery', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Choose from gallery', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
