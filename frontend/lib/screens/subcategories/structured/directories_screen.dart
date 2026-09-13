import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Structured → Directories. Prototype placeholder — ready for real content.
class DirectoriesScreen extends StatelessWidget {
  const DirectoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.map_rounded,
      title: 'Directories',
      description: 'Organizations, people & places',
    );
  }
}
