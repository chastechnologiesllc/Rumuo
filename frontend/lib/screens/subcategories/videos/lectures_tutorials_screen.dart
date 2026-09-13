import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Videos → Lectures & Tutorials. Prototype placeholder — ready for real content.
class LecturesTutorialsScreen extends StatelessWidget {
  const LecturesTutorialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.school_rounded,
      title: 'Lectures & Tutorials',
      description: 'Step-by-step teaching and how-tos',
    );
  }
}
