import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearch;

  const CustomAppBar({super.key, required this.title, this.showSearch = false});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        if (showSearch)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
        IconButton(
          icon: const Icon(Icons.filter_alt),
          onPressed: () => Navigator.pushNamed(context, '/advanced_search'),
        ),
        IconButton(
          icon: const Icon(Icons.category),
          onPressed: () => Navigator.pushNamed(context, '/genres'),
        ),
        IconButton(
          icon: const Icon(Icons.favorite),
          onPressed: () => Navigator.pushNamed(context, '/wishlist'),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}