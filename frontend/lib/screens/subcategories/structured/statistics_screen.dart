import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Structured → Statistics. Prototype placeholder — ready for real content.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.bar_chart_rounded,
      title: 'Statistics',
      description: 'Figures, trends and benchmarks',
    );
  }
}
