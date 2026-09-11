import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class HelpFeedbackScreen extends StatelessWidget {
  const HelpFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & feedback')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 720 : double.infinity),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  _HelpCard(
                    icon: Icons.search_rounded,
                    title: 'How search works',
                    body: 'Rumuo searches videos, shorts, blogs, books, channels, and categories. Normal searches are kept locally so you can return to them later.',
                  ),
                  _HelpCard(
                    icon: Icons.visibility_off_outlined,
                    title: 'Private search',
                    body: 'Private searches are designed not to add new entries to your local Sessions and tabs list. Use Delete browsing data to remove existing sessions.',
                  ),
                  _HelpCard(
                    icon: Icons.feedback_outlined,
                    title: 'Send feedback',
                    body: 'Copy the support address below and tell us what happened, what you expected, and which device or browser you used.',
                    action: TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(const ClipboardData(text: 'support@rumuo.app'));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback address copied')));
                        }
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy support address'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Rumuo · by chAs Technologies LLC', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted(context), fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;
  const _HelpCard({required this.icon, required this.title, required this.body, this.action});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(icon, color: AppTheme.gold), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)))]),
            const SizedBox(height: 12),
            Text(body, style: TextStyle(color: AppTheme.textSecondary(context), height: 1.45)),
            if (action != null) Align(alignment: Alignment.centerLeft, child: action!),
          ]),
        ),
      );
}
