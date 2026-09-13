import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Shorts → Quick Explanations. Prototype placeholder — ready for real content.
class QuickExplanationsScreen extends StatelessWidget {
  const QuickExplanationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.bolt_rounded,
      title: 'Quick Explanations',
      description: 'Fast, focused explainers',
    );
  }
}
