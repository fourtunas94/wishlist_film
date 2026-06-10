import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/wishlist.dart';
import '../services/wishlist_service.dart';

class WishlistProvider extends ChangeNotifier {
  List<ShareableWishlist> _wishlists = [];

  List<ShareableWishlist> get wishlists => _wishlists;

  WishlistProvider() {
    loadWishlists();
  }

  void loadWishlists() {
    _wishlists = WishlistService.getAllWishlists();
    notifyListeners();
  }

  void createWishlist(String name) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newWishlist = ShareableWishlist(id: newId, name: name, movies: []);
    WishlistService.saveWishlist(newWishlist);
    loadWishlists();
  }

  void editWishlistName(String wishlistId, String newName) {
    final wishlist = WishlistService.getWishlist(wishlistId);
    if (wishlist != null) {
      final updated = ShareableWishlist(
        id: wishlist.id,
        name: newName,
        movies: wishlist.movies,
      );
      WishlistService.saveWishlist(updated);
      loadWishlists();
    }
  }

  void addToWishlist(String wishlistId, Movie movie) {
    final wishlist = WishlistService.getWishlist(wishlistId);
    if (wishlist != null && !wishlist.movies.any((m) => m.id == movie.id)) {
      final updated = ShareableWishlist(
        id: wishlist.id,
        name: wishlist.name,
        movies: [...wishlist.movies, movie],
      );
      WishlistService.saveWishlist(updated);
      loadWishlists();
    }
  }

  void removeFromWishlist(String wishlistId, int movieId) {
    final wishlist = WishlistService.getWishlist(wishlistId);
    if (wishlist != null) {
      final updated = ShareableWishlist(
        id: wishlist.id,
        name: wishlist.name,
        movies: wishlist.movies.where((m) => m.id != movieId).toList(),
      );
      WishlistService.saveWishlist(updated);
      loadWishlists();
    }
  }

  bool isInWishlist(String wishlistId, int movieId) {
    final wishlist = WishlistService.getWishlist(wishlistId);
    return wishlist?.movies.any((m) => m.id == movieId) ?? false;
  }

  void deleteWishlist(String id) {
    WishlistService.deleteWishlist(id);
    loadWishlists();
  }
}