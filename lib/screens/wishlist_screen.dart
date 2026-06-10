import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/wishlist_provider.dart';
import '../models/wishlist.dart';
import '../services/wishlist_service.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  String? _selectedWishlistId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WishlistProvider>(context, listen: false);
      if (provider.wishlists.isNotEmpty && _selectedWishlistId == null) {
        setState(() => _selectedWishlistId = provider.wishlists.first.id);
      }
    });
  }

  void _createNewWishlist() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Wishlist Baru'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Contoh: Film Favorit, Nonton Bareng, Horor',
            labelText: 'Nama Wishlist',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) Navigator.pop(context, name);
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
    if (result != null) {
      Provider.of<WishlistProvider>(context, listen: false).createWishlist(result);
      // pilih wishlist yang baru dibuat
      await Future.delayed(const Duration(milliseconds: 100));
      final provider = Provider.of<WishlistProvider>(context, listen: false);
      if (provider.wishlists.isNotEmpty) {
        setState(() => _selectedWishlistId = provider.wishlists.last.id);
      }
    }
  }

  void _editWishlistName(ShareableWishlist wishlist) async {
    final nameController = TextEditingController(text: wishlist.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Nama Wishlist'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nama wishlist'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) Navigator.pop(context, name);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (newName != null && newName != wishlist.name) {
      Provider.of<WishlistProvider>(context, listen: false)
          .editWishlistName(wishlist.id, newName);
    }
  }

  void _shareWishlist(ShareableWishlist wishlist) {
    final shareLink = WishlistService.generateShareLink(wishlist);
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bagikan Wishlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            QrImageView(data: shareLink, version: QrVersions.auto, size: 200),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Share.share(shareLink),
              icon: const Icon(Icons.share),
              label: const Text('Bagikan via Aplikasi Lain'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWishlistPicker(
      BuildContext context, List<ShareableWishlist> wishlists) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[500],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Pilih Wishlist',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            itemCount: wishlists.length,
            itemBuilder: (ctx, i) {
              final w = wishlists[i];
              final isSelected = w.id == _selectedWishlistId;
              return ListTile(
                leading: Icon(
                  Icons.favorite,
                  color: isSelected ? Colors.purple : Colors.grey,
                ),
                title: Text(w.name),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.purple)
                    : null,
                onTap: () {
                  setState(() => _selectedWishlistId = w.id);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WishlistProvider>(context);
    final wishlists = provider.wishlists;

    ShareableWishlist? selectedWishlist;
    if (wishlists.isNotEmpty) {
      if (_selectedWishlistId == null || !wishlists.any((w) => w.id == _selectedWishlistId)) {
        selectedWishlist = wishlists.first;
        _selectedWishlistId = selectedWishlist.id;
      } else {
        selectedWishlist = wishlists.firstWhere((w) => w.id == _selectedWishlistId);
      }
    }

    final movies = selectedWishlist?.movies ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewWishlist,
            tooltip: 'Buat wishlist baru',
          ),
        ],
      ),
      body: Column(
        children: [
          if (wishlists.isNotEmpty)
            InkWell(
              onTap: () => _showWishlistPicker(context, wishlists),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade700),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.list, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedWishlist?.name ?? 'Pilih Wishlist',
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),
          if (selectedWishlist != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit nama wishlist',
                  onPressed: () => _editWishlistName(selectedWishlist!),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Bagikan wishlist',
                  onPressed: () => _shareWishlist(selectedWishlist!),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Hapus wishlist',
                  onPressed: () {
                    provider.deleteWishlist(selectedWishlist!.id);
                    setState(() {
                      if (provider.wishlists.isNotEmpty) {
                        _selectedWishlistId = provider.wishlists.first.id;
                      } else {
                        _selectedWishlistId = null;
                      }
                    });
                  },
                ),
              ],
            ),
          Expanded(
            child: movies.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Belum ada film di wishlist ini'),
                        SizedBox(height: 8),
                        Text(
                          'Tambahkan film dari halaman Home, Search, atau Genre',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: movies.length,
                    itemBuilder: (context, index) {
                      final movie = movies[index];
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/detail', arguments: movie),
                        child: Card(
                          child: Column(
                            children: [
                              Expanded(
                                child: Image.network(
                                  movie.posterUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(
                                  movie.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () => provider.removeFromWishlist(selectedWishlist!.id, movie.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}