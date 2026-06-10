import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/api_service.dart';
import '../widgets/movie_card.dart';
import '../models/movie.dart';

/// Screen generik untuk menampilkan film berdasarkan pemeran atau studio.
/// [subtitle] opsional (misal: nama karakter untuk cast).
class MoviesListScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? avatarUrl; // foto pemeran / logo studio
  final Future<List<Movie>> Function(int page) fetchMovies;

  const MoviesListScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.avatarUrl,
    required this.fetchMovies,
  });

  @override
  State<MoviesListScreen> createState() => _MoviesListScreenState();
}

class _MoviesListScreenState extends State<MoviesListScreen> {
  final ApiService _apiService = ApiService();
  final List<Movie> _movies = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    if (!_hasMore || _loading && _movies.isNotEmpty) return;
    setState(() => _loading = true);
    try {
      final movies = await widget.fetchMovies(_page);
      if (movies.isNotEmpty) {
        _movies.addAll(movies);
        _page++;
      } else {
        _hasMore = false;
      }
    } catch (_) {
      _hasMore = false;
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loading) {
      _loadMovies();
    }
  }

  Future<String?> _showWishlistDialog(
      BuildContext context, WishlistProvider provider) async {
    if (provider.wishlists.isEmpty) {
      provider.createWishlist('Wishlist Saya');
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Wishlist'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.wishlists.length,
            itemBuilder: (ctx, i) {
              final w = provider.wishlists[i];
              return ListTile(
                title: Text(w.name),
                onTap: () => Navigator.pop(ctx, w.id),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: widget.avatarUrl != null
            ? Row(children: [
                ClipOval(
                  child: Image.network(
                    widget.avatarUrl!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, size: 32),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(widget.title,
                      overflow: TextOverflow.ellipsis),
                ),
              ])
            : Text(widget.title),
      ),
      body: _movies.isEmpty && _loading
          ? const Center(child: CircularProgressIndicator())
          : _movies.isEmpty
              ? Center(
                  child: Text(
                    'Tidak ada film untuk "${widget.title}"',
                    textAlign: TextAlign.center,
                  ),
                )
              : GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _movies.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _movies.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final movie = _movies[index];
                    return MovieCard(
                      movie: movie,
                      isWishlisted: false,
                      onWishlistToggle: () async {
                        final selectedId =
                            await _showWishlistDialog(context, wishlistProvider);
                        if (selectedId != null) {
                          if (wishlistProvider.isInWishlist(
                              selectedId, movie.id)) {
                            wishlistProvider.removeFromWishlist(
                                selectedId, movie.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Dihapus dari wishlist')),
                            );
                          } else {
                            wishlistProvider.addToWishlist(selectedId, movie);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Ditambahkan ke wishlist')),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
    );
  }
}
