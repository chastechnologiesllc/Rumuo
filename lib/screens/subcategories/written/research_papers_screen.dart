import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Written → Research Papers. Prototype placeholder — ready for real content.
class ResearchPapersScreen extends StatelessWidget {
  const ResearchPapersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.description_rounded,
      title: 'Research Papers',
      description: 'Academic and professional research',
    );
  }
}
