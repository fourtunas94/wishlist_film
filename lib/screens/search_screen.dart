import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/movie_provider.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/movie_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    final results = await Provider.of<MovieProvider>(context, listen: false).searchMovies(query);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
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
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Cari film...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _performSearch('');
            },
          ),
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? const Center(child: Text('Tidak ada hasil ditemukan'))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  padding: const EdgeInsets.all(8),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final movie = _searchResults[index];
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