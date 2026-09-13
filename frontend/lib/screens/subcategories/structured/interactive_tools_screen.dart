import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Structured → Interactive Tools. Prototype placeholder — ready for real content.
class InteractiveToolsScreen extends StatelessWidget {
  const InteractiveToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.widgets_rounded,
      title: 'Interactive Tools',
      description: 'Simulations and hands-on tools',
    );
  }
}
