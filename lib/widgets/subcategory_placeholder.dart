import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared "coming soon" body used by every subcategory screen that
/// doesn't have real content wired up yet.
class SubcategoryPlaceholderBody extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const SubcategoryPlaceholderBody({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.gold, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted(context)),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.dividerColor(context)),
              ),
              child: Text(
                'Coming soon — building this out',
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard Scaffold shell every prototype subcategory screen uses, so
/// each screen file only needs to supply its own icon/title/description.
class SubcategoryScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const SubcategoryScaffold({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(title),
      ),
      body: SubcategoryPlaceholderBody(icon: icon, title: title, description: description),
    );
  }
}
