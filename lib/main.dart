import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/movie.dart';
import 'models/genre.dart';
import 'models/wishlist.dart';
import 'providers/movie_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/genre_provider.dart';
import 'services/genre_history_service.dart';
import 'services/wishlist_service.dart';
import 'screens/home_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/search_screen.dart';
import 'screens/advanced_search_screen.dart';
import 'screens/genre_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Daftarkan semua adapter
  Hive.registerAdapter(MovieAdapter());
  Hive.registerAdapter(GenreAdapter());
  Hive.registerAdapter(ShareableWishlistAdapter());
  
  // Inisialisasi service (mereka akan membuka box sendiri)
  await WishlistService.init(); // membuka wishlistBox dengan tipe ShareableWishlist
  await GenreHistoryService.init(); // membuka genreHistoryBox
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MovieProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => GenreProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Four X Movie',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.purple,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/wishlist': (context) => const WishlistScreen(),
          '/search': (context) => const SearchScreen(),
          '/advanced_search': (context) => const AdvancedSearchScreen(),
          '/genres': (context) => const GenreListScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/detail') {
            final movie = settings.arguments as Movie;
            return MaterialPageRoute(
              builder: (context) => DetailScreen(movie: movie),
            );
          }
          return null;
        },
      ),
    );
  }
}