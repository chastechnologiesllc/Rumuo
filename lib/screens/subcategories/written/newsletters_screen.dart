import 'package:flutter/material.dart';

import '../../../widgets/subcategory_placeholder.dart';

/// Written → Newsletters. Prototype placeholder — ready for real content.
class NewslettersScreen extends StatelessWidget {
  const NewslettersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubcategoryScaffold(
      icon: Icons.mail_rounded,
      title: 'Newsletters',
      description: 'Recurring written updates',
    );
  }
}
