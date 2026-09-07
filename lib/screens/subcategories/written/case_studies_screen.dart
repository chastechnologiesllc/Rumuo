import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Written → Case Studies. Prototype placeholder — ready for real content.
class CaseStudiesScreen extends StatelessWidget {
  const CaseStudiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.fact_check_rounded,
      title: 'Case Studies',
      description: 'Real-world breakdowns and lessons',
    );
  }
}
