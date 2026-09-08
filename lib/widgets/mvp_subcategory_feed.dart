import 'package:flutter/material.dart';

import '../data/subcategory_data.dart';
import '../models/information_form.dart';
import '../models/subcategory.dart';
import '../screens/subcategory_router.dart';
import '../theme/app_theme.dart';

class _MvpItem {
  final Subcategory subcategory;
  final String title;
  final String summary;
  final String meta;

  const _MvpItem({
    required this.subcategory,
    required this.title,
    required this.summary,
    required this.meta,
  });
}

/// Prototype content stream for a primary tab. It deliberately mixes every
/// subcategory under the selected form so the MVP behaves like a real feed,
/// while each card remains clearly labeled with its source subcategory.
class MvpSubcategoryFeed extends StatelessWidget {
  final InformationForm form;

  const MvpSubcategoryFeed({required this.form, super.key});

  List<_MvpItem> _items() {
    final subcategories = SubcategoryData.forForm(form);
    final items = <_MvpItem>[];
    for (final subcategory in subcategories) {
      items.addAll([
        _MvpItem(
          subcategory: subcategory,
          title: '${subcategory.name}: the essential starting point',
          summary:
              'A clear, practical introduction with examples and useful next steps.',
          meta: 'Featured',
        ),
        _MvpItem(
          subcategory: subcategory,
          title: 'What to know about ${subcategory.name.toLowerCase()}',
          summary:
              'A concise guide designed to help you understand the topic and apply it.',
          meta: 'Guide',
        ),
        _MvpItem(
          subcategory: subcategory,
          title: '${subcategory.name} in practice',
          summary:
              'A real-world example showing how the ideas work beyond the definition.',
          meta: 'Case study',
        ),
      ]);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items();
    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: () async {},
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _MvpContentCard(
            item: item,
            onTap: () => openSubcategory(context, item.subcategory),
          );
        },
      ),
    );
  }
}

class _MvpContentCard extends StatelessWidget {
  final _MvpItem item;
  final VoidCallback onTap;

  const _MvpContentCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerColor(context), width: 0.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.subcategory.name,
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(item.meta,
                      style: TextStyle(
                          color: AppTheme.textMuted(context), fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(item.subcategory.icon,
                        color: AppTheme.gold, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(item.summary,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: AppTheme.textMuted(context),
                                    height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppTheme.gold),
                  const SizedBox(width: 5),
                  const Text('Open content',
                      style: TextStyle(
                          color: AppTheme.gold, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      );
}
