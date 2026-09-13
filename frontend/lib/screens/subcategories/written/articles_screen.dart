import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Written → Articles. Prototype placeholder — ready for real content.
class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.article_rounded,
      title: 'Articles',
      description: 'Standalone written pieces',
    );
  }
}
