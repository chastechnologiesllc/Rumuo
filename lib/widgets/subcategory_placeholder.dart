import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A reusable prototype item used to populate subcategories before their
/// production data sources are connected.
class _PrototypeItem {
  final String title;
  final String summary;
  final String meta;

  const _PrototypeItem(this.title, this.summary, this.meta);
}

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

  List<_PrototypeItem> _itemsFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('interview')) {
      return const [
        _PrototypeItem('How experts solve hard problems', 'A practical conversation about decisions, trade-offs and lessons learned.', '18 min'),
        _PrototypeItem('Building useful things from first principles', 'An accessible interview with a builder on learning, craft and execution.', '24 min'),
        _PrototypeItem('The people behind the progress', 'Stories from practitioners changing their industries one project at a time.', '31 min'),
      ];
    }
    if (lower.contains('lecture') || lower.contains('course')) {
      return const [
        _PrototypeItem('Foundations: a clear starting point', 'A structured introduction that turns the core ideas into an easy learning path.', 'Lesson 1'),
        _PrototypeItem('From concept to confident practice', 'Step-by-step teaching with examples, exercises and checkpoints.', 'Lesson 2'),
        _PrototypeItem('Common mistakes and better methods', 'A practical guide to improving results through repeatable habits.', 'Lesson 3'),
      ];
    }
    if (lower.contains('research') || lower.contains('paper')) {
      return const [
        _PrototypeItem('A plain-language research briefing', 'The question, method, findings and limitations explained without the jargon.', '8 min read'),
        _PrototypeItem('What the evidence says so far', 'A balanced summary of findings, disagreements and open questions.', '12 min read'),
        _PrototypeItem('Methods worth understanding', 'A guided look at how to read claims, samples and results critically.', '10 min read'),
      ];
    }
    if (lower.contains('dataset')) {
      return const [
        _PrototypeItem('Explore a starter dataset', 'A clean, annotated collection ready for filtering, comparison and discovery.', '1,240 records'),
        _PrototypeItem('How to read a dataset', 'Learn the fields, sources, caveats and questions hidden inside structured data.', 'Guide'),
        _PrototypeItem('Data story: patterns that matter', 'A worked example showing how raw records become useful insight.', 'Case study'),
      ];
    }
    if (lower.contains('statistic')) {
      return const [
        _PrototypeItem('The numbers behind the headline', 'A visual, plain-language explanation of a widely used benchmark.', 'Briefing'),
        _PrototypeItem('Compare trends over time', 'See how a metric changes, what drives it and where interpretation can go wrong.', 'Interactive'),
        _PrototypeItem('Statistics for everyday decisions', 'A practical introduction to averages, rates, uncertainty and context.', 'Guide'),
      ];
    }
    if (lower.contains('calculator')) {
      return const [
        _PrototypeItem('Personal finance calculator', 'Estimate savings growth, monthly contributions and long-term outcomes.', 'Try it'),
        _PrototypeItem('Project planning estimator', 'Turn a goal, timeline and available resources into a simple working estimate.', 'Try it'),
        _PrototypeItem('Learning time planner', 'Build a realistic weekly plan around the time you actually have.', 'Try it'),
      ];
    }
    if (lower.contains('director')) {
      return const [
        _PrototypeItem('Find a trusted starting point', 'Browse a curated directory of useful organizations, services and communities.', 'Directory'),
        _PrototypeItem('Local resources worth knowing', 'A practical collection of places and people that can help you move forward.', 'Directory'),
        _PrototypeItem('Build your own resource map', 'Learn how to evaluate, save and organize useful contacts and references.', 'Guide'),
      ];
    }
    if (lower.contains('tool')) {
      return const [
        _PrototypeItem('Idea-to-plan workspace', 'A guided tool for turning a rough idea into clear next steps.', 'Open tool'),
        _PrototypeItem('Decision comparison canvas', 'Compare options by effort, value, risk and the evidence you have.', 'Open tool'),
        _PrototypeItem('Learning roadmap builder', 'Arrange topics, resources and milestones into a path you can follow.', 'Open tool'),
      ];
    }
    return [
      _PrototypeItem('A practical introduction to $name', 'A clear starting point with the essential ideas, examples and next steps.', 'Featured'),
      _PrototypeItem('What is worth knowing first', 'A concise guide that helps you build context before going deeper.', 'Guide'),
      _PrototypeItem('Learn by seeing it in practice', 'A real-world example showing how the ideas work beyond the definition.', 'Case study'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsFor(title);
    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: () async {},
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.gold, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            )),
                    const SizedBox(height: 3),
                    Text(description,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textMuted(context))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...items.map((item) => _PrototypeCard(
                title: item.title,
                summary: item.summary,
                meta: item.meta,
                tag: title,
              )),
        ],
      ),
    );
  }
}

class _PrototypeCard extends StatelessWidget {
  final String title;
  final String summary;
  final String meta;
  final String tag;

  const _PrototypeCard({
    required this.title,
    required this.summary,
    required this.meta,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) => Container(
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
                    tag,
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Text(meta,
                    style: TextStyle(
                        color: AppTheme.textMuted(context), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(summary,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textMuted(context), height: 1.35)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.arrow_forward_rounded,
                    size: 16, color: AppTheme.gold),
                const SizedBox(width: 5),
                Text('Explore',
                    style: const TextStyle(
                        color: AppTheme.gold, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      );
}

/// Standard Scaffold shell every prototype subcategory screen uses.
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
      body: SubcategoryPlaceholderBody(
        icon: icon,
        title: title,
        description: description,
      ),
    );
  }
}
