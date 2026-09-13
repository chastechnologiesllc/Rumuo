import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class _ResourceItem {
  final String title;
  final String summary;
  final String meta;
  final String type;
  const _ResourceItem(this.title, this.summary, this.meta, this.type);
}

/// Shared frontend-only experience for routes awaiting provider data.
class SubcategoryPlaceholderBody extends StatefulWidget {
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
  State<SubcategoryPlaceholderBody> createState() =>
      _SubcategoryPlaceholderBodyState();
}

class _SubcategoryPlaceholderBodyState
    extends State<SubcategoryPlaceholderBody> {
  String _query = '';
  String _filter = 'All';
  final Set<int> _saved = <int>{};

  List<_ResourceItem> _resources() {
    final name = widget.title.toLowerCase();
    if (name.contains('dataset')) {
      return const [
        _ResourceItem('Explore a starter dataset', 'An annotated collection ready for filtering, comparison and discovery.', '1,240 records', 'Collections'),
        _ResourceItem('How to read a dataset', 'Understand fields, provenance, caveats and the questions hidden in structured data.', 'Guide', 'Guides'),
        _ResourceItem('Data story: patterns that matter', 'A worked example showing how raw records become useful insight.', 'Case study', 'Stories'),
      ];
    }
    if (name.contains('statistic')) {
      return const [
        _ResourceItem('The numbers behind the headline', 'A plain-language explanation of a widely used benchmark.', 'Briefing', 'Briefings'),
        _ResourceItem('Compare trends over time', 'See how a metric changes and where interpretation can go wrong.', 'Interactive', 'Interactive'),
        _ResourceItem('Statistics for everyday decisions', 'A practical introduction to averages, rates, uncertainty and context.', 'Guide', 'Guides'),
      ];
    }
    if (name.contains('calculator') || name.contains('tool')) {
      return const [
        _ResourceItem('Personal planning workspace', 'Turn a goal, timeline and available resources into a clear estimate.', 'Try it', 'Interactive'),
        _ResourceItem('Decision comparison canvas', 'Compare options by effort, value, risk and the evidence available.', 'Open tool', 'Interactive'),
        _ResourceItem('Learning roadmap builder', 'Arrange topics, resources and milestones into a path you can follow.', 'Open tool', 'Guides'),
      ];
    }
    if (name.contains('research') || name.contains('paper')) {
      return const [
        _ResourceItem('A plain-language research briefing', 'Question, method, findings and limitations explained without jargon.', '8 min read', 'Briefings'),
        _ResourceItem('What the evidence says so far', 'A balanced summary of findings, disagreements and open questions.', '12 min read', 'Briefings'),
        _ResourceItem('Methods worth understanding', 'A guided look at claims, samples and results.', '10 min read', 'Guides'),
      ];
    }
    if (name.contains('interview')) {
      return const [
        _ResourceItem('How experts solve hard problems', 'A practical conversation about decisions, trade-offs and lessons learned.', '18 min', 'Conversations'),
        _ResourceItem('Building useful things from first principles', 'An accessible interview with a builder on learning and execution.', '24 min', 'Conversations'),
        _ResourceItem('The people behind the progress', 'Stories from practitioners changing their industries one project at a time.', '31 min', 'Stories'),
      ];
    }
    if (name.contains('lecture') || name.contains('course')) {
      return const [
        _ResourceItem('Foundations: a clear starting point', 'A structured introduction that turns core ideas into an easy learning path.', 'Lesson 1', 'Lessons'),
        _ResourceItem('From concept to confident practice', 'Step-by-step teaching with examples, exercises and checkpoints.', 'Lesson 2', 'Lessons'),
        _ResourceItem('Common mistakes and better methods', 'A practical guide to improving results through repeatable habits.', 'Lesson 3', 'Guides'),
      ];
    }
    if (name.contains('director')) {
      return const [
        _ResourceItem('Find a trusted starting point', 'Browse useful organizations, services and communities.', 'Directory', 'Collections'),
        _ResourceItem('Local resources worth knowing', 'A practical collection of places and people that can help you move forward.', 'Directory', 'Collections'),
        _ResourceItem('Build your own resource map', 'Learn how to evaluate, save and organize useful references.', 'Guide', 'Guides'),
      ];
    }
    return [
      _ResourceItem('A practical introduction to ${widget.title}', 'A clear starting point with essential ideas, examples and next steps.', 'Featured', 'Featured'),
      _ResourceItem('What is worth knowing first', 'A concise guide that builds context before you go deeper.', 'Guide', 'Guides'),
      _ResourceItem('Learn by seeing it in practice', 'A real-world example showing how the ideas work beyond the definition.', 'Case study', 'Stories'),
    ];
  }

  void _message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final all = _resources();
    final filters = <String>['All', ...all.map((item) => item.type).toSet()];
    final query = _query.trim().toLowerCase();
    final visible = all.asMap().entries.where((entry) {
      final item = entry.value;
      return (_filter == 'All' || item.type == _filter) &&
          (query.isEmpty || item.title.toLowerCase().contains(query) || item.summary.toLowerCase().contains(query));
    }).toList();

    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: () async => setState(() {}),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 760 ? 32.0 : 16.0;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 32),
            children: [
              Center(child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: _IntroCard(
                  icon: widget.icon,
                  title: widget.title,
                  description: widget.description,
                  onResearch: () => _message('Research workspace will open here.'),
                ),
              )),
              const SizedBox(height: 16),
              Center(child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search this collection',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppTheme.surfaceColor(context),
                    border: _border(context),
                    enabledBorder: _border(context),
                  ),
                ),
              )),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    return ChoiceChip(
                      label: Text(filter),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                      selectedColor: AppTheme.gold.withValues(alpha: 0.22),
                      side: BorderSide(color: AppTheme.dividerColor(context)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                _EmptyState(onReset: () => setState(() { _query = ''; _filter = 'All'; }))
              else
                ...visible.map((entry) => _ResourceCard(
                  item: entry.value,
                  saved: _saved.contains(entry.key),
                  onSave: () => setState(() => _saved.contains(entry.key) ? _saved.remove(entry.key) : _saved.add(entry.key)),
                  onOpen: () => _message('${entry.value.title} is ready to explore.'),
                  onResearch: () => _message('Added ${entry.value.title} to research.'),
                )),
            ],
          );
        },
      ),
    );
  }

  OutlineInputBorder _border(BuildContext context) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: AppTheme.dividerColor(context)),
  );
}

class _IntroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onResearch;

  const _IntroCard({required this.icon, required this.title, required this.description, required this.onResearch});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [AppTheme.gold.withValues(alpha: 0.18), AppTheme.surfaceColor(context)]),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.gold.withValues(alpha: 0.28)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: AppTheme.gold, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: Colors.white, size: 27)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(description, style: TextStyle(color: AppTheme.textMuted(context), height: 1.35)),
        const SizedBox(height: 11),
        OutlinedButton.icon(onPressed: onResearch, icon: const Icon(Icons.travel_explore_rounded, size: 17), label: const Text('Research this topic'), style: OutlinedButton.styleFrom(foregroundColor: AppTheme.gold, side: BorderSide(color: AppTheme.gold.withValues(alpha: 0.55)))),
      ])),
    ]),
  );
}

class _ResourceCard extends StatelessWidget {
  final _ResourceItem item;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onOpen;
  final VoidCallback onResearch;

  const _ResourceCard({required this.item, required this.saved, required this.onSave, required this.onOpen, required this.onResearch});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppTheme.surfaceColor(context), borderRadius: BorderRadius.circular(17), border: Border.all(color: AppTheme.dividerColor(context), width: 0.7)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: AppTheme.gold.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)), child: Text(item.type, style: const TextStyle(color: AppTheme.gold, fontSize: 11, fontWeight: FontWeight.w800))),
        const Spacer(),
        Text(item.meta, style: TextStyle(color: AppTheme.textMuted(context), fontSize: 11)),
        IconButton(tooltip: saved ? 'Remove from saved' : 'Save resource', onPressed: onSave, visualDensity: VisualDensity.compact, icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: saved ? AppTheme.gold : AppTheme.textMuted(context), size: 20)),
      ]),
      const SizedBox(height: 8),
      Text(item.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text(item.summary, style: TextStyle(color: AppTheme.textMuted(context), height: 1.35)),
      const SizedBox(height: 10),
      Row(children: [
        TextButton.icon(onPressed: onOpen, icon: const Icon(Icons.open_in_new_rounded, size: 16), label: const Text('Explore')),
        TextButton.icon(onPressed: onResearch, icon: const Icon(Icons.add_circle_outline_rounded, size: 16), label: const Text('Research')),
        const Spacer(),
        Icon(Icons.verified_outlined, size: 15, color: AppTheme.textMuted(context)),
        const SizedBox(width: 4),
        Text('Source context', style: TextStyle(color: AppTheme.textMuted(context), fontSize: 11)),
      ]),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onReset;
  const _EmptyState({required this.onReset});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(color: AppTheme.surfaceColor(context), borderRadius: BorderRadius.circular(17), border: Border.all(color: AppTheme.dividerColor(context))),
    child: Column(children: [
      Icon(Icons.search_off_rounded, size: 38, color: AppTheme.textMuted(context)),
      const SizedBox(height: 10),
      Text('No matching resources', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 5),
      Text('Try another phrase or reset the collection filters.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted(context))),
      const SizedBox(height: 12),
      OutlinedButton(onPressed: onReset, child: const Text('Reset filters')),
    ]),
  );
}

class SubcategoryScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const SubcategoryScaffold({required this.icon, required this.title, required this.description, super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.bgColor(context),
    appBar: AppBar(backgroundColor: AppTheme.bgColor(context), surfaceTintColor: Colors.transparent, elevation: 0, title: Text(title)),
    body: SubcategoryPlaceholderBody(icon: icon, title: title, description: description),
  );
}

typedef SubcategoryContentBody = SubcategoryPlaceholderBody;
