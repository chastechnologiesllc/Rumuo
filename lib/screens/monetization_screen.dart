import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MonetizationScreen extends StatelessWidget {
  const MonetizationScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.bgColor(context),
        appBar: AppBar(
          backgroundColor: AppTheme.bgColor(context),
          surfaceTintColor: Colors.transparent,
          title: const Text('Rumuo plans'),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return ListView(
              padding: EdgeInsets.fromLTRB(wide ? 32 : 16, 18, wide ? 32 : 16, 36),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: _HeroCard(onPro: () => _showUnavailable(context, 'Rumuo Pro')),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: wide
                        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(child: _PlanCard(title: 'Free discovery', eyebrow: 'START HERE', icon: Icons.explore_rounded, description: 'A broad, trusted way to discover useful knowledge across Rumuo’s five information forms.', features: const ['Personalized feed', 'Search and saved resources', 'Category discovery', 'Private search option'], action: 'Current experience', onPressed: null)),
                            const SizedBox(width: 14),
                            Expanded(child: _PlanCard(title: 'Pro research', eyebrow: 'GO DEEPER', icon: Icons.travel_explore_rounded, description: 'More capability for people who need longer investigations and reusable research context.', features: const ['Deep research investigations', 'Source comparison', 'Persistent workspaces', 'Monitoring and alerts'], action: 'Explore Pro', onPressed: () => _showUnavailable(context, 'Rumuo Pro'))),
                          ])
                        : Column(children: [
                            _PlanCard(title: 'Free discovery', eyebrow: 'START HERE', icon: Icons.explore_rounded, description: 'A broad, trusted way to discover useful knowledge across Rumuo’s five information forms.', features: const ['Personalized feed', 'Search and saved resources', 'Category discovery', 'Private search option'], action: 'Current experience', onPressed: null),
                            const SizedBox(height: 14),
                            _PlanCard(title: 'Pro research', eyebrow: 'GO DEEPER', icon: Icons.travel_explore_rounded, description: 'More capability for people who need longer investigations and reusable research context.', features: const ['Deep research investigations', 'Source comparison', 'Persistent workspaces', 'Monitoring and alerts'], action: 'Explore Pro', onPressed: () => _showUnavailable(context, 'Rumuo Pro')),
                          ]),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: _FutureCard(onEnterprise: () => _showUnavailable(context, 'Enterprise Intelligence')),
                  ),
                ),
              ],
            );
          },
        ),
      );

  static void _showUnavailable(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name will be available when billing is connected.')));
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onPro;
  const _HeroCard({required this.onPro});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.gold.withValues(alpha: 0.24), AppTheme.surfaceColor(context)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 54, height: 54, alignment: Alignment.center, decoration: BoxDecoration(color: AppTheme.surfaceColor(context), borderRadius: BorderRadius.circular(17), border: Border.all(color: AppTheme.dividerColor(context))), child: Icon(Icons.auto_awesome_rounded, color: AppTheme.textColor(context), size: 28)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pay for capability, not basic discovery.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text('Rumuo keeps everyday knowledge discovery broad. Premium plans are designed for depth, research continuity and professional intelligence.', style: TextStyle(color: AppTheme.textMuted(context), height: 1.4)),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: onPro, icon: const Icon(Icons.arrow_forward_rounded, size: 17), label: const Text('See Pro research')),
          ])),
        ]),
      );
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String eyebrow;
  final IconData icon;
  final String description;
  final List<String> features;
  final String action;
  final VoidCallback? onPressed;

  const _PlanCard({required this.title, required this.eyebrow, required this.icon, required this.description, required this.features, required this.action, required this.onPressed});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        color: AppTheme.surfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppTheme.dividerColor(context))),
        child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, color: AppTheme.textColor(context)), const SizedBox(width: 9), Text(eyebrow, style: TextStyle(color: AppTheme.textColor(context), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1))]),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(description, style: TextStyle(color: AppTheme.textMuted(context), height: 1.35)),
          const SizedBox(height: 14),
          ...features.map((feature) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Icon(Icons.check_circle_outline_rounded, color: AppTheme.textColor(context), size: 18), const SizedBox(width: 8), Expanded(child: Text(feature))]))),
          const SizedBox(height: 7),
          SizedBox(width: double.infinity, child: onPressed == null ? OutlinedButton(onPressed: null, child: Text(action)) : OutlinedButton(onPressed: onPressed, child: Text(action))),
        ])),
      );
}

class _FutureCard extends StatelessWidget {
  final VoidCallback onEnterprise;
  const _FutureCard({required this.onEnterprise});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        color: AppTheme.surfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppTheme.dividerColor(context))),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(18, 12, 10, 12),
          leading: Icon(Icons.apartment_rounded, color: AppTheme.textColor(context), size: 28),
          title: const Text('Enterprise intelligence', style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: const Padding(padding: EdgeInsets.only(top: 4), child: Text('Monitored research spaces, team workspaces, alerts and structured discovery for organizations.')),
          trailing: IconButton(tooltip: 'Learn more', onPressed: onEnterprise, icon: const Icon(Icons.chevron_right_rounded)),
        ),
      );
}
