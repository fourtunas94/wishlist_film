import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/genre_provider.dart';
import 'genre_movies_screen.dart';

class GenreListScreen extends StatelessWidget {
  const GenreListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final genreProvider = Provider.of<GenreProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Genre Film')),
      body: genreProvider.loadingGenres
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
              ),
              itemCount: genreProvider.genres.length,
              itemBuilder: (context, index) {
                final genre = genreProvider.genres[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GenreMoviesScreen(
                            genreId: genre.id,
                            genreName: genre.name,
                          ),
                        ),
                      );
                    },
                    child: Center(child: Text(genre.name, style: const TextStyle(fontSize: 18))),
                  ),
                );
              },
            ),
    );
  }
}