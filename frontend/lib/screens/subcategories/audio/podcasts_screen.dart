import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Audio → Podcasts. Prototype placeholder — ready for real content.
class PodcastsScreen extends StatelessWidget {
  const PodcastsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.podcasts_rounded,
      title: 'Podcasts',
      description: 'Episodic audio conversations',
    );
  }
}
