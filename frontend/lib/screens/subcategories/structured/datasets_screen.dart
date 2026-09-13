import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Structured → Datasets. Prototype placeholder — ready for real content.
class DatasetsScreen extends StatelessWidget {
  const DatasetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.storage_rounded,
      title: 'Datasets',
      description: 'Structured data to explore',
    );
  }
}
