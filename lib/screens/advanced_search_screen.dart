import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/movie_card.dart';
import '../models/movie.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  _AdvancedSearchScreenState createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final ApiService _apiService = ApiService();

  int? _selectedCastId;
  String? _selectedCastName;
  int? _selectedCompanyId;
  String? _selectedCompanyName;

  final TextEditingController _castController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _minYearController = TextEditingController();
  final TextEditingController _maxYearController = TextEditingController();

  List<Map<String, dynamic>> _castSuggestions = [];
  List<Map<String, dynamic>> _companySuggestions = [];

  List<Movie> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  // Counter untuk membatalkan hasil API yang sudah usang
  int _castSearchGen = 0;
  int _companySearchGen = 0;

  final DraggableScrollableController _sheetController = DraggableScrollableController();

  // Overlay untuk rekomendasi floating
  final LayerLink _castLayerLink = LayerLink();
  final LayerLink _companyLayerLink = LayerLink();
  OverlayEntry? _castOverlay;
  OverlayEntry? _companyOverlay;

  @override
  void initState() {
    super.initState();
    _castController.addListener(_onCastTextChanged);
    _companyController.addListener(_onCompanyTextChanged);
  }

  @override
  void dispose() {
    _removeCastOverlay();
    _removeCompanyOverlay();
    _castController.removeListener(_onCastTextChanged);
    _companyController.removeListener(_onCompanyTextChanged);
    _castController.dispose();
    _companyController.dispose();
    _minYearController.dispose();
    _maxYearController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // ── Overlay helpers ─────────────────────────────────────────────────────────

  void _showCastOverlay() {
    if (!mounted || _castSuggestions.isEmpty) {
      _removeCastOverlay();
      return;
    }
    if (_castOverlay != null) {
      _castOverlay!.markNeedsBuild();
      return;
    }
    _castOverlay = OverlayEntry(
      builder: (ctx) => CompositedTransformFollower(
        link: _castLayerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.grey[850],
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _castSuggestions.length,
                itemBuilder: (ctx, i) {
                  final cast = _castSuggestions[i];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => _selectCast(cast),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(
                        cast['name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_castOverlay!);
  }

  void _removeCastOverlay() {
    _castOverlay?.remove();
    _castOverlay = null;
  }

  void _showCompanyOverlay() {
    if (!mounted || _companySuggestions.isEmpty) {
      _removeCompanyOverlay();
      return;
    }
    if (_companyOverlay != null) {
      _companyOverlay!.markNeedsBuild();
      return;
    }
    _companyOverlay = OverlayEntry(
      builder: (ctx) => CompositedTransformFollower(
        link: _companyLayerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.grey[850],
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _companySuggestions.length,
                itemBuilder: (ctx, i) {
                  final company = _companySuggestions[i];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => _selectCompany(company),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(
                        company['name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_companyOverlay!);
  }

  void _removeCompanyOverlay() {
    _companyOverlay?.remove();
    _companyOverlay = null;
  }

  // ── Text change handlers ─────────────────────────────────────────────────────

  void _onCastTextChanged() async {
    final gen = ++_castSearchGen;
    final query = _castController.text;
    if (query.length < 2) {
      _castSuggestions = [];
      _removeCastOverlay();
      return;
    }
    final suggestions = await _apiService.searchPersonAutocomplete(query);
    if (mounted && gen == _castSearchGen) {
      _castSuggestions = suggestions;
      _showCastOverlay();
    }
  }

  void _onCompanyTextChanged() async {
    final gen = ++_companySearchGen;
    final query = _companyController.text;
    if (query.length < 2) {
      _companySuggestions = [];
      _removeCompanyOverlay();
      return;
    }
    final suggestions = await _apiService.searchCompanyAutocomplete(query);
    if (mounted && gen == _companySearchGen) {
      _companySuggestions = suggestions;
      _showCompanyOverlay();
    }
  }

  void _selectCast(Map<String, dynamic> cast) {
    _castSearchGen++; // batalkan hasil API yang pending
    _removeCastOverlay();
    _castController.removeListener(_onCastTextChanged);
    setState(() {
      _selectedCastId = cast['id'] as int;
      _selectedCastName = cast['name'];
      _castController.text = cast['name'];
      _castSuggestions = [];
    });
    _castController.addListener(_onCastTextChanged);
  }

  void _selectCompany(Map<String, dynamic> company) {
    _companySearchGen++; // batalkan hasil API yang pending
    _removeCompanyOverlay();
    _companyController.removeListener(_onCompanyTextChanged);
    setState(() {
      _selectedCompanyId = company['id'] as int;
      _selectedCompanyName = company['name'];
      _companyController.text = company['name'];
      _companySuggestions = [];
    });
    _companyController.addListener(_onCompanyTextChanged);
  }

  Future<void> _performSearch() async {
    _removeCastOverlay();
    _removeCompanyOverlay();
    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    int? minYear = _minYearController.text.isNotEmpty
        ? int.tryParse(_minYearController.text)
        : null;
    int? maxYear = _maxYearController.text.isNotEmpty
        ? int.tryParse(_maxYearController.text)
        : null;

    try {
      List<Movie> movies;
      if (_selectedCastId == null &&
          _selectedCompanyId == null &&
          minYear == null &&
          maxYear == null) {
        movies = await _apiService.getPopularMovies(page: 1);
      } else {
        movies = await _apiService.discoverMoviesWithFilters(
          minYear: minYear,
          maxYear: maxYear,
          withCastId: _selectedCastId,
          withCompanyId: _selectedCompanyId,
        );
      }
      if (mounted) {
        setState(() {
          _searchResults = movies;
          _isSearching = false;
        });
        if (movies.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada film ditemukan.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _clearFilters() {
    _removeCastOverlay();
    _removeCompanyOverlay();
    setState(() {
      _selectedCastId = null;
      _selectedCastName = null;
      _selectedCompanyId = null;
      _selectedCompanyName = null;
      _castController.clear();
      _companyController.clear();
      _minYearController.clear();
      _maxYearController.clear();
      _castSuggestions = [];
      _companySuggestions = [];
      _searchResults = [];
      _hasSearched = false;
    });
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

  // ── Form builder (dipakai di kedua state) ────────────────────────────────────

  Widget _buildForm({required EdgeInsets padding}) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pemeran
          CompositedTransformTarget(
            link: _castLayerLink,
            child: TextField(
              controller: _castController,
              decoration: const InputDecoration(
                labelText: 'Nama Pemeran (Aktor/Aktris)',
                border: OutlineInputBorder(),
                hintText: 'Contoh: Tom Holland',
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Studio
          CompositedTransformTarget(
            link: _companyLayerLink,
            child: TextField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Nama Studio',
                border: OutlineInputBorder(),
                hintText: 'Contoh: Marvel Studios',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minYearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tahun dari',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxYearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tahun sampai',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _performSearch,
            icon: const Icon(Icons.search),
            label: const Text('Cari Film'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  // ── Results grid ─────────────────────────────────────────────────────────────

  Widget _buildResults(WishlistProvider wishlistProvider) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Tidak ada film ditemukan',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final movie = _searchResults[index];
        return MovieCard(
          movie: movie,
          isWishlisted: false,
          onWishlistToggle: () async {
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
                  const SnackBar(content: Text('Ditambahkan ke wishlist')),
                );
              }
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencarian Lanjutan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearFilters,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: !_hasSearched
          // ── Sebelum pencarian: form penuh ────────────────────────────────
          ? _buildForm(padding: const EdgeInsets.all(16))
          // ── Setelah pencarian: form di belakang, sheet hasil bisa ditarik ─
          : Stack(
              children: [
                _buildForm(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 16, bottom: 320),
                ),
                DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: 0.45,
                  minChildSize: 0.12,
                  maxChildSize: 0.95,
                  snap: true,
                  snapSizes: const [0.12, 0.45, 0.95],
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Handle drag
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragUpdate: (details) {
                              final screenHeight =
                                  MediaQuery.of(context).size.height;
                              final delta = -details.delta.dy / screenHeight;
                              final newSize =
                                  (_sheetController.size + delta).clamp(0.12, 0.95);
                              _sheetController.jumpTo(newSize);
                            },
                            onVerticalDragEnd: (details) {
                              final size = _sheetController.size;
                              double target;
                              if (size < 0.28) {
                                target = 0.12;
                              } else if (size < 0.70) {
                                target = 0.45;
                              } else {
                                target = 0.95;
                              }
                              _sheetController.animateTo(
                                target,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[500],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Label jumlah hasil
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _isSearching
                                  ? 'Mencari...'
                                  : '${_searchResults.length} film ditemukan',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          // Hasil
                          Expanded(
                            child: _isSearching
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : _searchResults.isEmpty
                                    ? const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.movie,
                                                size: 64,
                                                color: Colors.grey),
                                            SizedBox(height: 12),
                                            Text('Tidak ada film ditemukan',
                                                style: TextStyle(
                                                    color: Colors.grey)),
                                          ],
                                        ),
                                      )
                                    : GridView.builder(
                                        controller: scrollController,
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.65,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        itemCount: _searchResults.length,
                                        itemBuilder: (context, index) {
                                          final movie = _searchResults[index];
                                          return MovieCard(
                                            movie: movie,
                                            isWishlisted: false,
                                            onWishlistToggle: () async {
                                              final selectedId =
                                                  await _showWishlistDialog(
                                                      context,
                                                      wishlistProvider);
                                              if (selectedId != null) {
                                                if (wishlistProvider
                                                    .isInWishlist(
                                                        selectedId, movie.id)) {
                                                  wishlistProvider
                                                      .removeFromWishlist(
                                                          selectedId, movie.id);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'Dihapus dari wishlist')),
                                                  );
                                                } else {
                                                  wishlistProvider
                                                      .addToWishlist(
                                                          selectedId, movie);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'Ditambahkan ke wishlist')),
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
                  },
                ),
              ],
            ),
    );
  }
}