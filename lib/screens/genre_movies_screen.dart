import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/genre_provider.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/movie_card.dart';
import '../models/movie.dart';

class GenreMoviesScreen extends StatefulWidget {
  final int genreId;
  final String genreName;
  const GenreMoviesScreen({super.key, required this.genreId, required this.genreName});

  @override
  _GenreMoviesScreenState createState() => _GenreMoviesScreenState();
}

class _GenreMoviesScreenState extends State<GenreMoviesScreen> {
  final List<Movie> _movies = [];
  bool _loading = true;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadMovies() async {
    if (!_hasMore) return;
    setState(() => _loading = true);
    final provider = Provider.of<GenreProvider>(context, listen: false);
    final movies = await provider.getMoviesByGenre(widget.genreId, page: _currentPage);
    if (movies.isNotEmpty) {
      _movies.addAll(movies);
      _currentPage++;
    } else {
      _hasMore = false;
    }
    setState(() => _loading = false);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_loading) {
      _loadMovies();
    }
  }

  Future<String?> _showWishlistDialog(BuildContext context, WishlistProvider provider) async {
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
            itemBuilder: (ctx, index) {
              final w = provider.wishlists[index];
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
      appBar: AppBar(title: Text(widget.genreName)),
      body: _movies.isEmpty && _loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              controller: _scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
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
                    final selectedId = await _showWishlistDialog(context, wishlistProvider);
                    if (selectedId != null) {
                      if (wishlistProvider.isInWishlist(selectedId, movie.id)) {
                        wishlistProvider.removeFromWishlist(selectedId, movie.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dihapus dari wishlist')),
                        );
                      } else {
                        wishlistProvider.addToWishlist(selectedId, movie);
                        ScaffoldMessenger.of(context).showSnackBar( 
                          const SnackBar(content: Text('Ditambahkan ke wishlist')),
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