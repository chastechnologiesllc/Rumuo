import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Shorts → Highlights. Prototype placeholder — ready for real content.
class HighlightsScreen extends StatelessWidget {
  const HighlightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.star_rounded,
      title: 'Highlights',
      description: 'Best moments, pulled out',
    );
  }
}
