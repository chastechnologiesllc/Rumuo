import 'package:flutter/material.dart';

import '../data/subcategory_data.dart';
import '../models/information_form.dart';
import '../models/subcategory.dart';
import '../theme/app_theme.dart';
import 'subcategory_router.dart';

/// "See all" destination for a shelf — every subcategory under [form],
/// not just the preview shown on the Feed screen.
class InformationFormScreen extends StatelessWidget {
  final InformationForm form;
  const InformationFormScreen({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    final subcategories = SubcategoryData.forForm(form);
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          form.label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              form.tagline,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted(context)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                itemCount: subcategories.length,
                itemBuilder: (context, i) {
                  final subcategory = subcategories[i];
                  return _SubcategoryTile(
                    subcategory: subcategory,
                    onTap: () => openSubcategory(context, subcategory),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubcategoryTile extends StatelessWidget {
  final Subcategory subcategory;
  final VoidCallback onTap;
  const _SubcategoryTile({required this.subcategory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor(context), width: 0.6),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(subcategory.icon, color: AppTheme.gold, size: 19),
                ),
                Text(
                  subcategory.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  subcategory.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textMuted(context), fontSize: 11),
                ),
              ],
            ),
            if (!subcategory.isLive)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'SOON',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: AppTheme.textMuted(context),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
