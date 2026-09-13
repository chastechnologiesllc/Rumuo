import 'package:flutter/material.dart';

import '../providers/feed_provider.dart';
import '../services/search_session_store.dart';
import '../theme/app_theme.dart';
import 'content_search_screen.dart';

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

  Future<void> _remove(String query) async {
    await SearchSessionStore.remove(query);
    if (mounted) {
      setState(() => _sessions = _sessions.where((item) => item != query).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        title: const Text('Session'),
        actions: [
          IconButton(
            tooltip: 'Feed',
            icon: Icon(
              Icons.home_outlined,
              color: dark ? Colors.white : Colors.black,
              size: 30,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 700 ? 4 : 2;
                return _sessions.isEmpty
                    ? const _EmptySessions()
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.18,
                        ),
                        itemCount: _sessions.length,
                        itemBuilder: (_, index) => _SessionCard(
                          query: _sessions[index],
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ContentSearchScreen(
                              feedProvider: widget.feedProvider,
                              initialQuery: _sessions[index],
                            ),
                          )),
                          onRemove: () => _remove(_sessions[index]),
                        ),
                      );
              },
            ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _SessionCard({required this.query, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history_rounded, size: 22, color: AppTheme.textSecondary(context)),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Remove session',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: onRemove,
                    ),
                  ],
                ),
                const Spacer(),
                Text(query, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.25)),
                const SizedBox(height: 4),
                Text('Open search', style: TextStyle(color: AppTheme.textMuted(context), fontSize: 12)),
              ],
            ),
          ),
        ),
      );
}

class _EmptySessions extends StatelessWidget {
  const _EmptySessions();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 52, color: AppTheme.textMuted(context)),
              const SizedBox(height: 12),
              const Text('No sessions yet', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Your normal searches will appear here.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted(context))),
            ],
          ),
        ),
      );
}
