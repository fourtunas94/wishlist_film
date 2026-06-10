import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/wishlist.dart';

class WishlistService {
  static late Box<ShareableWishlist> _box;

  static Future<void> init() async {
    _box = await Hive.openBox<ShareableWishlist>('wishlistBox');
  }

  static List<ShareableWishlist> getAllWishlists() {
    return _box.values.toList();
  }

  static void saveWishlist(ShareableWishlist wishlist) {
    _box.put(wishlist.id, wishlist);
  }

  static void deleteWishlist(String id) {
    _box.delete(id);
  }

  static ShareableWishlist? getWishlist(String id) {
    return _box.get(id);
  }

  static String generateShareLink(ShareableWishlist wishlist) {
    final jsonString = jsonEncode(wishlist.toJson());
    final encodedData = base64Url.encode(utf8.encode(jsonString));
    return 'fourwishlist://wishlist/share?data=$encodedData';
  }

  static ShareableWishlist? parseSharedLink(Uri uri) {
    if (uri.scheme == 'fourwishlist' && uri.path == '/wishlist/share') {
      final encodedData = uri.queryParameters['data'];
      if (encodedData != null) {
        try {
          final jsonString = utf8.decode(base64Url.decode(encodedData));
          final Map<String, dynamic> data = jsonDecode(jsonString);
          return ShareableWishlist.fromJson(data);
        } catch (e) {
          print('Error parsing shared wishlist: $e');
        }
      }
    }
    return null;
  }
}