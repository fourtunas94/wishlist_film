import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/movie_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/genre_provider.dart';
import '../models/genre.dart';
import '../widgets/movie_card.dart';
import '../widgets/custom_app_bar.dart';
import 'genre_movies_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MovieProvider>(context, listen: false).loadPopularMovies();
      Provider.of<GenreProvider>(context, listen: false).refreshFavoriteGenres();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      Provider.of<MovieProvider>(context, listen: false).loadPopularMovies();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Fungsi untuk menampilkan dialog pilih wishlist
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
    final movieProvider = Provider.of<MovieProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final genreProvider = Provider.of<GenreProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'F X M', showSearch: true),
      body: Column(
        children: [
          if (genreProvider.favoriteGenres.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('Genre Favoritmu',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: genreProvider.favoriteGenres.length,
                    itemBuilder: (context, index) {
                      final genre = genreProvider.favoriteGenres[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Chip(
                          label: Text(genre.name),
                          backgroundColor: Colors.purple,
                          labelStyle: const TextStyle(color: Colors.white),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                          onDeleted: () =>
                              genreProvider.removeFavoriteGenre(genre.id),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),

          Expanded(
            child: movieProvider.popularMovies.isEmpty && movieProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    controller: _scrollController,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    padding: const EdgeInsets.all(8),
                    itemCount: movieProvider.popularMovies.length + (movieProvider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == movieProvider.popularMovies.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final movie = movieProvider.popularMovies[index];
                      return MovieCard(
                        movie: movie,
                        isWishlisted: false, // Tidak perlu isWishlisted karena kita pilih wishlist via dialog
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
          ),
        ],
      ),
    );
  }
}