import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

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
    final link = 'https://rumuo.app/search?q=${Uri.encodeComponent(query ?? '')}';
    return SafeArea(
      child: Material(
        color: AppTheme.surfaceColor(context),
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Close',
                  icon: Icon(Icons.close_rounded, color: AppTheme.textColor(context), size: 21),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              _ToolTile(icon: Icons.add_rounded, title: 'New search', onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => ContentSearchScreen(feedProvider: feedProvider)));
              }),
              _ToolTile(icon: Icons.delete_sweep_outlined, title: 'Delete browsing data', onTap: () {
                Navigator.pop(context);
                showDialog<void>(context: context, builder: (_) => const Dialog(child: DeleteBrowsingDataSheet()));
              }),
              _ToolTile(icon: Icons.bookmark_border_rounded, title: 'Bookmarks', onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavedScreen()));
              }),
              _ToolTile(icon: Icons.share_outlined, title: 'Share', onTap: () async {
                Navigator.pop(context);
                await Share.share(link, subject: query?.isNotEmpty == true ? 'Rumuo search: $query' : 'Rumuo search');
              }),
              _ToolTile(icon: Icons.settings_outlined, title: 'Settings', onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchSettingsScreen()));
              }),
              _ToolTile(icon: Icons.help_outline_rounded, title: 'Help & feedback', onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpFeedbackScreen()));
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class DeleteBrowsingDataSheet extends StatefulWidget {
  const DeleteBrowsingDataSheet({super.key});
  @override
  State<DeleteBrowsingDataSheet> createState() => _DeleteBrowsingDataSheetState();
}

class _DeleteBrowsingDataSheetState extends State<DeleteBrowsingDataSheet> {
  bool _sessions = true;
  bool _cookies = true;
  bool _cache = true;
  bool _privatePreference = true;
  bool _deleting = false;

  Future<void> _delete() async {
    setState(() => _deleting = true);
    await SearchSessionStore.clearBrowsingData(
      sessions: _sessions,
      cookies: _cookies,
      cache: _cache,
      privatePreference: _privatePreference,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected browsing data deleted')));
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Delete browsing data', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Remove local Rumuo browsing state from this device.', style: TextStyle(color: AppTheme.textMuted(context))),
              const SizedBox(height: 12),
              _CheckRow(title: 'Search sessions', value: _sessions, onChanged: (v) => setState(() => _sessions = v)),
              _CheckRow(title: 'Cookies and site data', value: _cookies, onChanged: (v) => setState(() => _cookies = v)),
              _CheckRow(title: 'Cached content', value: _cache, onChanged: (v) => setState(() => _cache = v)),
              _CheckRow(title: 'Private-search preference', value: _privatePreference, onChanged: (v) => setState(() => _privatePreference = v)),
              const SizedBox(height: 10),
              FilledButton.icon(onPressed: _deleting || !(_sessions || _cookies || _cache || _privatePreference) ? null : _delete, icon: _deleting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.delete_outline_rounded), label: const Text('Delete selected data')),
            ],
          ),
        ),
      );
}

class _CheckRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CheckRow({required this.title, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => CheckboxListTile(contentPadding: EdgeInsets.zero, value: value, onChanged: (v) => onChanged(v ?? false), title: Text(title));
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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await SearchSessionStore.privateSearchEnabled();
    if (mounted) setState(() { _privateDefault = value; _loading = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Search settings')),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  Card(child: SwitchListTile.adaptive(value: _privateDefault, onChanged: (value) async { setState(() => _privateDefault = value); await SearchSessionStore.setPrivateSearchEnabled(value); }, title: const Text('Offer private search first'), subtitle: const Text('Keep private search available from the search bar.'))),
                  const SizedBox(height: 12),
                  Card(child: ListTile(leading: Icon(Icons.lock_outline_rounded, color: AppTheme.textColor(context)), title: const Text('Local session storage'), subtitle: const Text('Normal sessions stay on this device and can be deleted from the overflow menu.'))),
                ],
              ),
      );
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ToolTile({required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
        leading: Icon(icon, color: AppTheme.textColor(context), size: 21),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textColor(context), size: 20),
        onTap: onTap,
      );
}
