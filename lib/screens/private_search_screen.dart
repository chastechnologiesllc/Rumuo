import 'package:flutter/material.dart';

import '../providers/feed_provider.dart';
import '../services/search_session_store.dart';
import '../theme/app_theme.dart';
import 'content_search_screen.dart';

class PrivateSearchScreen extends StatelessWidget {
  final FeedProvider feedProvider;
  const PrivateSearchScreen({required this.feedProvider, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        title: const Text('Private search'),
        actions: [
          IconButton(
            tooltip: 'Private search settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            final content = Padding(
              padding: EdgeInsets.symmetric(horizontal: wide ? 48 : 24, vertical: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.visibility_off_rounded, size: wide ? 88 : 72, color: AppTheme.gold),
                  const SizedBox(height: 22),
                  Text('Search privately', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text('Rumuo will not add searches from this session to your saved search history. Your existing bookmarks and app settings remain available.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted(context), height: 1.5)),
                  const SizedBox(height: 28),
                  _PrivacyNote(icon: Icons.history_rounded, text: 'Searches from this session are not saved.'),
                  _PrivacyNote(icon: Icons.bookmark_border_rounded, text: 'Bookmarks are saved only when you choose to bookmark them.'),
                  _PrivacyNote(icon: Icons.devices_rounded, text: 'This setting applies to this device and browser session.'),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Start private search'),
                    onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => ContentSearchScreen(feedProvider: feedProvider, privateMode: true),
                    )),
                  ),
                ],
              ),
            );
            return Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: wide ? 620 : 560), child: content));
          },
        ),
      ),
    );
  }

  Future<void> _showSettings(BuildContext context) async {
    final current = await SearchSessionStore.privateSearchEnabled();
    if (!context.mounted) return;
    var enabled = current;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Private search settings'),
          content: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Open private search by default'),
            subtitle: const Text('Keep private search available as the first option in Sessions and tabs.'),
            value: enabled,
            onChanged: (value) async {
              setDialogState(() => enabled = value);
              await SearchSessionStore.setPrivateSearchEnabled(value);
            },
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Done'))],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PrivacyNote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary(context)),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );
}
