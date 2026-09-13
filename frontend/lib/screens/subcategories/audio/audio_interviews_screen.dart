import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Audio → Interviews. Prototype placeholder — ready for real content.
class AudioInterviewsScreen extends StatelessWidget {
  const AudioInterviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.mic_rounded,
      title: 'Interviews',
      description: 'Audio-only expert interviews',
    );
  }
}
