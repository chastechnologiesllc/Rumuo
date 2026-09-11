import 'package:flutter/material.dart';

import '../providers/feed_provider.dart';
import '../services/search_session_store.dart';
import '../theme/app_theme.dart';
import 'content_search_screen.dart';
import 'private_search_screen.dart';

class SearchSessionsScreen extends StatefulWidget {
  final FeedProvider feedProvider;
  const SearchSessionsScreen({required this.feedProvider, super.key});

  @override
  State<SearchSessionsScreen> createState() => _SearchSessionsScreenState();
}

class _SearchSessionsScreenState extends State<SearchSessionsScreen> {
  List<String> _sessions = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await SearchSessionStore.loadSessions();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  Future<void> _clearAll() async {
    await SearchSessionStore.clear();
    if (mounted) setState(() => _sessions = const []);
  }

  Future<void> _remove(String query) async {
    await SearchSessionStore.remove(query);
    if (mounted) setState(() => _sessions = _sessions.where((item) => item != query).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        title: const Text('Sessions and tabs'),
        actions: [
          if (_sessions.isNotEmpty)
            TextButton(onPressed: _clearAll, child: const Text('Clear all')),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth >= 720 ? 680.0 : double.infinity;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                      children: [
                        _SectionCard(
                          icon: Icons.visibility_off_rounded,
                          title: 'Private search',
                          subtitle: 'Search without saving this session to your history.',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => PrivateSearchScreen(feedProvider: widget.feedProvider),
                          )),
                        ),
                        const SizedBox(height: 24),
                        Text('Recent searches', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        if (_sessions.isEmpty)
                          _EmptySessions()
                        else
                          ..._sessions.map((query) => ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                leading: const Icon(Icons.history_rounded),
                                title: Text(query, maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: IconButton(
                                  tooltip: 'Remove search',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => _remove(query),
                                ),
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ContentSearchScreen(
                                    feedProvider: widget.feedProvider,
                                    initialQuery: query,
                                  ),
                                )),
                              )),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SectionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: AppTheme.gold.withValues(alpha: 0.14),
            child: Icon(icon, color: AppTheme.gold),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      );
}

class _EmptySessions extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 48, color: AppTheme.textMuted(context)),
            const SizedBox(height: 12),
            const Text('No saved sessions yet', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Your normal searches will appear here. Private searches stay out of this list.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted(context))),
          ],
        ),
      );
}
