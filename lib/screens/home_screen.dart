import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/information_form.dart';
import '../providers/feed_provider.dart';
import '../services/scroll_visibility_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mvp_subcategory_feed.dart';
import 'content_search_screen.dart';
import 'channels_screen.dart';
import 'saved_screen.dart';

/// The Feed screen uses horizontal primary tabs, matching the original Rumuo
/// navigation: Videos, Shorts, Audio, Written, and Datasets. Blogs and Books
/// are subcategories inside Written rather than primary tabs of their own.
class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenSaved;

  const HomeScreen({super.key, this.onOpenSaved});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _forms = [
    InformationForm.videos,
    InformationForm.shorts,
    InformationForm.audio,
    InformationForm.written,
    InformationForm.structured,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: ScrollVisibilityService.instance.visible,
              builder: (context, visible, child) => AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: visible
                    ? child
                    : const SizedBox(width: double.infinity, height: 0),
              ),
              child: _HeaderAndSearch(onOpenSaved: widget.onOpenSaved),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
              child: Divider(
                height: 1,
                thickness: 1.4,
                color: AppTheme.dividerColor(context),
              ),
            ),
            _PrimaryTabs(
              forms: _forms,
              selectedIndex: _selectedIndex,
              onSelected: (index) => setState(() => _selectedIndex = index),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification:
                    ScrollVisibilityService.instance.handleScrollNotification,
                child: _TabContent(form: _forms[_selectedIndex]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAndSearch extends StatelessWidget {
  final VoidCallback? onOpenSaved;

  const _HeaderAndSearch({this.onOpenSaved});

  @override
  Widget build(BuildContext context) {
    void openSearch() => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ContentSearchScreen(
              feedProvider: context.read<FeedProvider>(),
            ),
          ),
        );

    final iconColor = AppTheme.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
        child: LayoutBuilder(
        builder: (context, constraints) {
          final searchWidth =
              (constraints.maxWidth * 0.68).clamp(210.0, 420.0).toDouble();
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          SizedBox(
            width: 34,
            child: IconButton(
              tooltip: 'Feed',
              onPressed: () {},
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.home_outlined, size: 32),
              color: AppTheme.textColor(context),
              splashRadius: 24,
              highlightColor: Colors.black.withValues(alpha: 0.22),
            ),
          ),
          const SizedBox(width: 2),
          SizedBox(
            width: searchWidth,
            child: _SearchBar(
                onTap: openSearch,
                action: openSearch,
                actionTooltip: 'Temporary search',
            ),
          ),
          const SizedBox(width: 2),
          SizedBox(
            width: 34,
            child: IconButton(
              tooltip: 'Saved',
              onPressed: onOpenSaved ??
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SavedScreen())),
              padding: EdgeInsets.zero,
              icon: Icon(Icons.bookmark_outline_rounded,
                  color: iconColor, size: 29),
            ),
          ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback action;
  final String actionTooltip;
  const _SearchBar({
    required this.onTap,
    required this.action,
    required this.actionTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchSurface = isDark
        ? const Color(0xFF2B2C30)
        : const Color(0xFFF1F3F4);

    return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: searchSurface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.dividerColor(context),
                width: 0.6,
              ),
            ),
            child: Row(
              children: [
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/icons/rumuo_bird_transparent.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    semanticLabel: 'Rumuo search',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Search through the world's knowledge",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: actionTooltip,
                  onPressed: action,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 28, minHeight: 28),
                  icon: Icon(Icons.visibility_off_rounded,
                      color: AppTheme.textSecondary(context), size: 21),
                ),
              ],
            ),
          ),
        ),
      );
}

}

class _PrimaryTabs extends StatelessWidget {
  final List<InformationForm> forms;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PrimaryTabs({
    required this.forms,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: Row(
          children: List.generate(forms.length, (index) {
            final selected = index == selectedIndex;
            final form = forms[index];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == forms.length - 1 ? 0 : 6),
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: form.label,
                  child: GestureDetector(
                    onTap: () => onSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.gold
                            : AppTheme.surfaceColor(context),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected
                              ? AppTheme.gold
                              : AppTheme.dividerColor(context),
                        ),
                      ),
                      child: Text(
                        form.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
}

class _TabContent extends StatelessWidget {
  final InformationForm form;
  const _TabContent({required this.form});

  @override
  Widget build(BuildContext context) {
    if (form == InformationForm.shorts) {
      return const ChannelsScreen(showAppBar: false);
    }
    return MvpSubcategoryFeed(form: form);
  }
}
