import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Audio → Lectures. Prototype placeholder — ready for real content.
class AudioLecturesScreen extends StatelessWidget {
  const AudioLecturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.school_rounded,
      title: 'Lectures',
      description: 'Recorded spoken lectures',
    );
  }
}
