import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Written → News & Reports. Prototype placeholder — ready for real content.
class NewsReportsScreen extends StatelessWidget {
  const NewsReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.newspaper_rounded,
      title: 'News & Reports',
      description: 'Current developments and reports',
    );
  }
}
