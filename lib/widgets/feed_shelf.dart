import 'package:flutter/material.dart';

import '../data/subcategory_data.dart';
import '../models/information_form.dart';
import '../screens/information_form_screen.dart';
import '../screens/subcategory_router.dart';
import '../theme/app_theme.dart';
import 'subcategory_card.dart';

/// One shelf on the Feed screen — a single [InformationForm] with its
/// subcategories scrolling horizontally. The five shelves themselves
/// stack vertically on the Feed screen (see home_screen.dart).
class FeedShelf extends StatelessWidget {
  final InformationForm form;
  const FeedShelf({required this.form, super.key});

  @override
  Widget build(BuildContext context) {
    final subcategories = SubcategoryData.forForm(form);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 2),
            child: Row(
              children: [
                Icon(form.icon, color: AppTheme.gold, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        form.label,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        form.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textMuted(context)),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _openSeeMore(context),
                  child: const Text(
                    'See all',
                    style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: kSubcategoryCardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: subcategories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                if (i == subcategories.length) {
                  return SeeMoreCard(onTap: () => _openSeeMore(context));
                }
                final subcategory = subcategories[i];
                return SubcategoryCard(
                  subcategory: subcategory,
                  onTap: () => openSubcategory(context, subcategory),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openSeeMore(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => InformationFormScreen(form: form)));
  }
}
