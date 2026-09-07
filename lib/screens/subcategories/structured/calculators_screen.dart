import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Structured → Calculators. Prototype placeholder — ready for real content.
class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.calculate_rounded,
      title: 'Calculators',
      description: 'Interactive problem-solving tools',
    );
  }
}
