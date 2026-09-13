import 'package:flutter/material.dart';

import '../services/network_policy.dart';
import '../services/search_session_store.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _privateSearch = true;
  bool _personalization = true;
  bool _researchMemory = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final privateSearch = await SearchSessionStore.privateSearchEnabled();
    if (!mounted) return;
    setState(() {
      _privateSearch = privateSearch;
      _loading = false;
    });
  }

  Future<void> _clearResearchHistory() async {
    await SearchSessionStore.clearSessions();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search and research history cleared.')),
    );
  }

  Future<void> _resetPersonalization() async {
    await UserProfileService.instance.clear();
    if (!mounted) return;
    setState(() => _personalization = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Personalization preferences reset.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final policy = NetworkPolicy.instance;
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              children: [
                _SettingsSection(
                  title: 'Discovery & personalization',
                  subtitle: 'Control how Rumuo learns from your activity.',
                  children: [
                    SwitchListTile.adaptive(
                      value: _personalization,
                      onChanged: (value) => setState(() => _personalization = value),
                      activeThumbColor: AppTheme.textColor(context),
                      activeTrackColor:
                          AppTheme.textColor(context).withValues(alpha: 0.3),
                      title: const Text('Personalized discovery'),
                      subtitle: const Text('Use selected interests and recent activity to shape the feed.'),
                    ),
                    SwitchListTile.adaptive(
                      value: _researchMemory,
                      onChanged: (value) => setState(() => _researchMemory = value),
                      activeThumbColor: AppTheme.textColor(context),
                      activeTrackColor:
                          AppTheme.textColor(context).withValues(alpha: 0.3),
                      title: const Text('Research continuity'),
                      subtitle: const Text('Keep useful context while you explore a topic.'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.restart_alt_rounded),
                      title: const Text('Reset personalization'),
                      subtitle: const Text('Clear selected interests and rebuild your discovery profile.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _resetPersonalization,
                    ),
                  ],
                ),
                _SettingsSection(
                  title: 'Privacy & search',
                  subtitle: 'Your private activity stays under your control.',
                  children: [
                    SwitchListTile.adaptive(
                      value: _privateSearch,
                      onChanged: (value) async {
                        setState(() => _privateSearch = value);
                        await SearchSessionStore.setPrivateSearchEnabled(value);
                      },
                      activeThumbColor: AppTheme.textColor(context),
                      activeTrackColor:
                          AppTheme.textColor(context).withValues(alpha: 0.3),
                      title: const Text('Offer private search first'),
                      subtitle: const Text('Search without adding activity to persistent sessions.'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep_outlined),
                      title: const Text('Delete research history'),
                      subtitle: const Text('Remove saved search sessions from this device.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _clearResearchHistory,
                    ),
                    ListTile(
                      leading: const Icon(Icons.security_outlined),
                      title: const Text('Privacy boundaries'),
                      subtitle: const Text('Rumuo should use your data to serve you, not sell your private history.'),
                    ),
                  ],
                ),
                _SettingsSection(
                  title: 'Performance & data',
                  subtitle: 'Choose how much data the app uses.',
                  children: [
                    SwitchListTile.adaptive(
                      value: policy.isDataSaverEnabled,
                      onChanged: (_) => policy.toggle(),
                      activeThumbColor: AppTheme.textColor(context),
                      activeTrackColor:
                          AppTheme.textColor(context).withValues(alpha: 0.3),
                      title: const Text('Data Saver'),
                      subtitle: const Text('Reduce preloading and background network use.'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.wifi_rounded),
                      title: const Text('Network status'),
                      subtitle: Text(policy.isConstrained ? 'Constrained mode is active.' : 'Normal network mode is active.'),
                    ),
                  ],
                ),
                _SettingsSection(
                  title: 'Account',
                  subtitle: 'Account actions will connect when authentication is enabled.',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout_rounded),
                      title: const Text('Sign out'),
                      subtitle: const Text('Available after account authentication is connected.'),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account authentication is not connected yet.'))),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 14),
        elevation: 0,
        color: AppTheme.surfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: AppTheme.dividerColor(context))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(color: AppTheme.textMuted(context), fontSize: 12)),
          ])),
          ...children,
          const SizedBox(height: 4),
        ]),
      );
}
