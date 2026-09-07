import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Shorts → Demonstrations. Prototype placeholder — ready for real content.
class DemonstrationsScreen extends StatelessWidget {
  const DemonstrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.build_circle_rounded,
      title: 'Demonstrations',
      description: 'Short hands-on demonstrations',
    );
  }
}
