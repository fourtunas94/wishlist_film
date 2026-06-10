import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../providers/wishlist_provider.dart';
import '../services/api_service.dart';
import 'movies_list_screen.dart';

class DetailScreen extends StatefulWidget {
  final Movie movie;
  const DetailScreen({super.key, required this.movie});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _apiService.getMovieDetailsWithCredits(widget.movie.id);
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

  static const String _imgBase = 'https://image.tmdb.org/t/p/w185';

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Text(title,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _buildCastSection(List<dynamic> cast) {
    if (cast.isEmpty) return const SizedBox.shrink();
    final displayed = cast.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Pemeran'),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayed.length,
            itemBuilder: (context, i) {
              final person = displayed[i];
              final profilePath = person['profile_path'] as String?;
              final avatarUrl = profilePath != null
                  ? '$_imgBase$profilePath'
                  : null;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MoviesListScreen(
                      title: person['name'] ?? 'Pemeran',
                      subtitle: person['character'],
                      avatarUrl: avatarUrl,
                      fetchMovies: (page) =>
                          _apiService.discoverMoviesWithFilters(
                        withCastId: person['id'] as int,
                        page: page,
                      ),
                    ),
                  ),
                ),
                child: Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: 10),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: profilePath != null
                            ? CachedNetworkImage(
                                imageUrl: '$_imgBase$profilePath',
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    const CircleAvatar(
                                        radius: 32,
                                        child: Icon(Icons.person)),
                              )
                            : const CircleAvatar(
                                radius: 32, child: Icon(Icons.person)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        person['name'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudiosSection(List<dynamic> companies) {
    if (companies.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Studio Produksi'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: companies.map<Widget>((c) {
            final logoPath = c['logo_path'] as String?;
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MoviesListScreen(
                    title: c['name'] ?? 'Studio',
                    fetchMovies: (page) =>
                        _apiService.discoverMoviesWithFilters(
                      withCompanyId: c['id'] as int,
                      page: page,
                    ),
                  ),
                ),
              ),
              child: Chip(
                avatar: logoPath != null
                    ? CachedNetworkImage(
                        imageUrl:
                            'https://image.tmdb.org/t/p/w92$logoPath',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.business, size: 16),
                      )
                    : const Icon(Icons.business, size: 16),
                label: Text(c['name'] ?? '',
                    style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.grey[850],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final movie = widget.movie;

    return Scaffold(
      appBar: AppBar(
        title: Text(movie.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.red),
            onPressed: () async {
              final selectedId =
                  await _showWishlistDialog(context, wishlistProvider);
              if (selectedId != null) {
                if (wishlistProvider.isInWishlist(selectedId, movie.id)) {
                  wishlistProvider.removeFromWishlist(selectedId, movie.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dihapus dari wishlist')),
                  );
                } else {
                  wishlistProvider.addToWishlist(selectedId, movie);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Ditambahkan ke wishlist')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Poster ──────────────────────────────────────────────────
            Stack(
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: movie.posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: movie.posterUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => Container(
                              color: Colors.grey,
                              child:
                                  const Icon(Icons.movie, size: 100)),
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.movie, size: 100)),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                            '${movie.voteAverage.toStringAsFixed(1)} / 10'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Detail Konten ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _detailFuture,
                builder: (context, snapshot) {
                  // Judul & tanggal selalu tampil
                  final header = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(movie.title,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Rilis: ${movie.formattedDate}',
                          style: const TextStyle(color: Colors.grey)),
                      _sectionTitle('Sinopsis'),
                      Text(movie.overview,
                          style: const TextStyle(height: 1.5)),
                    ],
                  );

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        header,
                        const SizedBox(height: 24),
                        const Center(child: CircularProgressIndicator()),
                      ],
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return header;
                  }

                  final data = snapshot.data!;
                  final cast = (data['credits']?['cast'] as List?) ?? [];
                  final companies =
                      (data['production_companies'] as List?) ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      _buildCastSection(cast),
                      _buildStudiosSection(companies),

                      // ── Film Serupa ───────────────────────────────────
                      _sectionTitle('Film Serupa'),
                      FutureBuilder<List<Movie>>(
                        future: _apiService.getSimilarMovies(movie.id),
                        builder: (context, simSnap) {
                          if (simSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                                height: 150,
                                child: Center(
                                    child: CircularProgressIndicator()));
                          }
                          if (!simSnap.hasData ||
                              simSnap.data!.isEmpty) {
                            return const SizedBox(
                                height: 50,
                                child: Center(
                                    child:
                                        Text('Tidak ada film serupa')));
                          }
                          return SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: simSnap.data!.length,
                              itemBuilder: (context, index) {
                                final similar = simSnap.data![index];
                                return GestureDetector(
                                  onTap: () =>
                                      Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            DetailScreen(movie: similar)),
                                  ),
                                  child: Container(
                                    width: 120,
                                    margin:
                                        const EdgeInsets.only(right: 8),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  similar.posterUrl,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) =>
                                                  const Icon(
                                                      Icons.broken_image),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          similar.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 12),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}