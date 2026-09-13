import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Videos → Documentaries. Prototype placeholder — ready for real content.
class DocumentariesScreen extends StatelessWidget {
  const DocumentariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.movie_filter_rounded,
      title: 'Documentaries',
      description: 'In-depth documentary features',
    );
  }
}
