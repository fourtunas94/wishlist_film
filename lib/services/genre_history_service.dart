import 'package:hive/hive.dart';

class GenreHistoryService {
  static const String boxName = 'genreHistoryBox';
  static late Box<int> _box;

  static Future<void> init() async {
    _box = await Hive.openBox<int>(boxName);
  }

  static void recordGenreOpen(int genreId) {
    int current = _box.get(genreId) ?? 0; // ✅ gunakan ?? 0
    _box.put(genreId, current + 1);
  }

  static List<int> getTopGenres({int limit = 5}) {
    final Map<dynamic, dynamic> map = _box.toMap();
    final entries = map.entries.toList();
    entries.sort((a, b) => (b.value as int).compareTo(a.value as int));
    return entries.take(limit).map((e) => e.key as int).toList();
  }

  static int getGenreOpenCount(int genreId) {
    return _box.get(genreId) ?? 0;
  }

  static void removeGenre(int genreId) {
    _box.delete(genreId);
  }
}