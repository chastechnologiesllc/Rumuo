import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Audio → Audio Courses. Prototype placeholder — ready for real content.
class AudioCoursesScreen extends StatelessWidget {
  const AudioCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.library_music_rounded,
      title: 'Audio Courses',
      description: 'Structured audio learning',
    );
  }
}
