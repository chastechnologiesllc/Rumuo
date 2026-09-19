import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/resource_api_service.dart';
import '../theme/app_theme.dart';

/// Shared resource experience for subcategories. Content comes only from the
/// verified backend; no UI copy is invented when the API is unavailable.
class SubcategoryPlaceholderBody extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? subcategoryId;

  const SubcategoryPlaceholderBody({required this.icon, required this.title, required this.description, this.subcategoryId, super.key});

  @override
  State<SubcategoryPlaceholderBody> createState() => _SubcategoryPlaceholderBodyState();
}

class _SubcategoryPlaceholderBodyState extends State<SubcategoryPlaceholderBody> {
  final _api = const ResourceApiService();
  late Future<List<ResourceRecord>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ResourceRecord>> _load() => _api.list(subcategory: widget.subcategoryId ?? _subcategoryForTitle(widget.title));

  String _subcategoryForTitle(String title) {
    final value = title.toLowerCase();
    if (value.contains('lecture') || value.contains('tutorial')) return 'videos_long_form';
    if (value.contains('paper')) return 'written_papers';
    if (value.contains('book')) return 'written_books';
    if (value.contains('dataset')) return 'structured_datasets';
    if (value.contains('statistic')) return 'structured_statistics';
    if (value.contains('calculator')) return 'structured_calculators';
    if (value.contains('tool')) return 'structured_tools';
    return 'written_articles';
  }

  void _refresh() => setState(() { _future = _load(); });

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    color: AppTheme.gold,
    onRefresh: () async => _refresh(),
    child: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 32), children: [
      _IntroCard(icon: widget.icon, title: widget.title, description: widget.description),
      const SizedBox(height: 16),
      TextField(onChanged: (value) => setState(() => _query = value), decoration: InputDecoration(hintText: 'Search verified resources', prefixIcon: const Icon(Icons.search_rounded), filled: true, fillColor: AppTheme.surfaceColor(context), border: _border(context), enabledBorder: _border(context))),
      const SizedBox(height: 16),
      FutureBuilder<List<ResourceRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
          if (snapshot.hasError) return _MessageState(icon: Icons.cloud_off_rounded, title: 'Resources are temporarily unavailable', detail: 'The verified resource service could not be reached. Try again later.', onRetry: _refresh);
          final query = _query.trim().toLowerCase();
          final resources = (snapshot.data ?? const <ResourceRecord>[]).where((r) => query.isEmpty || '${r.title} ${r.summary} ${r.publisher}'.toLowerCase().contains(query)).toList();
          if (resources.isEmpty) return _MessageState(icon: Icons.search_off_rounded, title: 'No verified resources yet', detail: 'This collection is empty until a source passes the evidence and review workflow.', onRetry: _refresh);
          return Column(children: resources.map((record) => _ResourceCard(record: record)).toList());
        },
      ),
    ]),
  );

  OutlineInputBorder _border(BuildContext context) => OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.dividerColor(context)));
}

class _IntroCard extends StatelessWidget {
  final IconData icon; final String title; final String description;
  const _IntroCard({required this.icon, required this.title, required this.description});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.gold.withValues(alpha: 0.18), AppTheme.surfaceColor(context)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.gold.withValues(alpha: 0.28))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: AppTheme.gold, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: Colors.white, size: 27)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(description, style: TextStyle(color: AppTheme.textMuted(context), height: 1.35)), const SizedBox(height: 10), Text('Verified sources only', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700, fontSize: 12))]))]));
}

class _ResourceCard extends StatelessWidget {
  final ResourceRecord record;
  const _ResourceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final sourceUrl = record.url;
    final provenanceUrl = record.provenanceUrl;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.dividerColor(context), width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Tag(label: record.contentType),
              _Tag(label: record.publisher),
              _Tag(label: record.trustState, accent: true),
            ],
          ),
          const SizedBox(height: 9),
          Text(record.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(record.summary, style: TextStyle(color: AppTheme.textMuted(context), height: 1.35)),
          const SizedBox(height: 10),
          Text('${record.region} · ${record.license ?? 'Licence not specified'}', style: TextStyle(color: AppTheme.textMuted(context), fontSize: 11)),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: sourceUrl == null ? null : () => launchUrl(sourceUrl, mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Open source'),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'View provenance',
                onPressed: provenanceUrl == null ? null : () => launchUrl(provenanceUrl, mode: LaunchMode.externalApplication),
                icon: Icon(Icons.fact_check_outlined, color: AppTheme.textMuted(context), size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool accent;
  const _Tag({required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: accent ? AppTheme.gold.withValues(alpha: 0.16) : AppTheme.surfaceColor(context),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: TextStyle(
      color: accent ? AppTheme.gold : AppTheme.textMuted(context),
      fontSize: 11,
      fontWeight: FontWeight.w700,
    )),
  );
}
class _MessageState extends StatelessWidget { final IconData icon; final String title; final String detail; final VoidCallback onRetry; const _MessageState({required this.icon, required this.title, required this.detail, required this.onRetry}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: AppTheme.surfaceColor(context), borderRadius: BorderRadius.circular(17), border: Border.all(color: AppTheme.dividerColor(context))), child: Column(children: [Icon(icon, size: 38, color: AppTheme.textMuted(context)), const SizedBox(height: 10), Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(detail, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted(context))), const SizedBox(height: 12), OutlinedButton(onPressed: onRetry, child: const Text('Try again'))])); }

class SubcategoryScaffold extends StatelessWidget {
  final IconData icon; final String title; final String description;
  const SubcategoryScaffold({required this.icon, required this.title, required this.description, super.key});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: AppTheme.bgColor(context), appBar: AppBar(backgroundColor: AppTheme.bgColor(context), surfaceTintColor: Colors.transparent, elevation: 0, title: Text(title)), body: SubcategoryPlaceholderBody(icon: icon, title: title, description: description));
}

typedef SubcategoryContentBody = SubcategoryPlaceholderBody;
