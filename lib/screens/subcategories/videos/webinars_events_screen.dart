import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Videos → Webinars & Events. Prototype placeholder — ready for real content.
class WebinarsEventsScreen extends StatelessWidget {
  const WebinarsEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.groups_rounded,
      title: 'Webinars & Events',
      description: 'Recorded talks and live sessions',
    );
  }
}
