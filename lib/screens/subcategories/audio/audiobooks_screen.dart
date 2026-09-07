import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Audio → Audiobooks. Prototype placeholder — ready for real content.
class AudiobooksScreen extends StatelessWidget {
  const AudiobooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.auto_stories_rounded,
      title: 'Audiobooks',
      description: 'Books narrated for listening',
    );
  }
}
