import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../providers/feed_provider.dart';
import '../services/search_session_store.dart';
import '../theme/app_theme.dart';
import 'content_search_screen.dart';
import 'help_feedback_screen.dart';
import 'saved_screen.dart';

class SearchToolsScreen extends StatelessWidget {
  final FeedProvider feedProvider;
  final String? query;
  const SearchToolsScreen({required this.feedProvider, this.query, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(title: const Text('Search options')),
      body: _ToolsList(
        children: [
          _ToolTile(icon: Icons.add_rounded, title: 'New search', subtitle: 'Start with a clean search field', onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ContentSearchScreen(feedProvider: feedProvider)))),
          _ToolTile(icon: Icons.delete_sweep_outlined, title: 'Delete browsing data', subtitle: 'Remove saved search sessions from this device', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DeleteBrowsingDataScreen()))),
          _ToolTile(icon: Icons.bookmark_border_rounded, title: 'Bookmarks', subtitle: 'Open content you saved in Rumuo', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavedScreen()))),
          _ToolTile(icon: Icons.share_outlined, title: 'Share', subtitle: 'Copy a shareable Rumuo search link', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchShareScreen(query: query)))),
          _ToolTile(icon: Icons.settings_outlined, title: 'Settings', subtitle: 'Control private search and session behavior', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchSettingsScreen()))),
          _ToolTile(icon: Icons.help_outline_rounded, title: 'Help & feedback', subtitle: 'Learn how search works or send feedback', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpFeedbackScreen()))),
        ],
      ),
    );
  }
}

class DeleteBrowsingDataScreen extends StatefulWidget {
  const DeleteBrowsingDataScreen({super.key});
  @override
  State<DeleteBrowsingDataScreen> createState() => _DeleteBrowsingDataScreenState();
}

class _DeleteBrowsingDataScreenState extends State<DeleteBrowsingDataScreen> {
  bool _sessions = true;
  bool _privateState = true;
  bool _deleting = false;

  Future<void> _delete() async {
    setState(() => _deleting = true);
    if (_sessions) await SearchSessionStore.clear();
    if (_privateState) await SearchSessionStore.setPrivateSearchEnabled(true);
    if (!mounted) return;
    setState(() => _deleting = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected browsing data deleted')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Delete browsing data')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Text('Choose what to remove', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('This only removes local Rumuo search state on this device. It does not delete bookmarks unless you remove them separately.', style: TextStyle(color: AppTheme.textMuted(context))),
            const SizedBox(height: 18),
            Card(child: Column(children: [
              CheckboxListTile(value: _sessions, onChanged: (v) => setState(() => _sessions = v ?? false), title: const Text('Search sessions'), subtitle: const Text('Recent searches and session badge count')),
              CheckboxListTile(value: _privateState, onChanged: (v) => setState(() => _privateState = v ?? false), title: const Text('Private search preference'), subtitle: const Text('Reset private-search preference to its default')),
            ])),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: _deleting || (!_sessions && !_privateState) ? null : _delete, icon: _deleting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.delete_outline_rounded), label: const Text('Delete selected data')),
          ],
        ),
      );
}

class SearchSettingsScreen extends StatefulWidget {
  const SearchSettingsScreen({super.key});
  @override
  State<SearchSettingsScreen> createState() => _SearchSettingsScreenState();
}

class _SearchSettingsScreenState extends State<SearchSettingsScreen> {
  bool _privateDefault = true;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final value = await SearchSessionStore.privateSearchEnabled(); if (mounted) setState(() { _privateDefault = value; _loading = false; }); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Search settings')),
        body: _loading ? const Center(child: CircularProgressIndicator(color: AppTheme.gold)) : ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Card(child: SwitchListTile.adaptive(value: _privateDefault, onChanged: (value) async { setState(() => _privateDefault = value); await SearchSessionStore.setPrivateSearchEnabled(value); }, title: const Text('Offer private search first'), subtitle: const Text('Keep private search prominent in Sessions and tabs.'))),
            const SizedBox(height: 12),
            Card(child: const ListTile(leading: Icon(Icons.lock_outline_rounded), title: Text('Local session storage'), subtitle: Text('Normal search sessions stay on this device and can be deleted at any time.'))),
          ],
        ),
      );
}

class SearchShareScreen extends StatelessWidget {
  final String? query;
  const SearchShareScreen({this.query, super.key});
  @override
  Widget build(BuildContext context) {
    final link = 'https://rumuo.app/search?q=${Uri.encodeComponent(query ?? '')}';
    return Scaffold(appBar: AppBar(title: const Text('Share search')), body: ListView(padding: const EdgeInsets.all(20), children: [
      const Icon(Icons.share_outlined, size: 64, color: AppTheme.gold),
      const SizedBox(height: 18),
      Text(query == null || query!.isEmpty ? 'Share Rumuo' : 'Share “$query”', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Text('Copy this link to share the search with another device or person.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted(context))),
      const SizedBox(height: 24),
      SelectableText(link, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary(context))),
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: () async { await Clipboard.setData(ClipboardData(text: link)); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search link copied'))); }, icon: const Icon(Icons.copy_rounded), label: const Text('Copy link')),
    ]));
  }
}

class _ToolsList extends StatelessWidget {
  final List<Widget> children;
  const _ToolsList({required this.children});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth >= 720 ? 680.0 : double.infinity;
        return Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: width), child: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 32), children: children)));
      });
}

class _ToolTile extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final VoidCallback onTap;
  const _ToolTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7), leading: Icon(icon, color: AppTheme.textColor(context)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right_rounded), onTap: onTap);
}
