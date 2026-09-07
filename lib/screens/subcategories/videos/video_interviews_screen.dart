import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Videos → Interviews. Prototype placeholder — ready for real content.
class VideoInterviewsScreen extends StatelessWidget {
  const VideoInterviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.record_voice_over_rounded,
      title: 'Interviews',
      description: 'One-on-one conversations with experts',
    );
  }
}
