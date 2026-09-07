# Frontend Restructure Audit — 2026-09-07

Scope: client-side (Flutter UI) only, per instruction. **No backend /
FeedProvider / data-source logic was restructured** — `FeedTab`
(`videos`/`shorts`/`blogs`/`books`) and the underlying providers/services
are untouched. This document records what changed, what's live vs.
prototype, and where the next backend work plugs in.

## 1. What changed

### 1.1 Header + search
- The old search **icon** in the top bar is replaced with a full-width
  **search bar**, sitting between the `Rumuo` header row and the feed
  (`lib/screens/home_screen.dart` → `_HeaderAndSearch` / `_SearchBar`).
- Tapping it opens the existing `ContentSearchScreen` — no search logic
  changed, only how it's surfaced.

### 1.2 Feed restructure — 4 tabs → 5 information forms
The old single-select tab row (Videos / Shorts / Blogs / Books) is
replaced with a **horizontal primary tab row** containing five tabs, one per
`InformationForm` (`lib/models/information_form.dart`):

**Videos → Shorts → Audio → Written → Datasets**

The selected tab displays its own feed below the horizontal pills. Blogs and
Books are subcategories of Written rather than primary tabs. Audio and
Datasets display their subcategory cards, while Videos and Shorts retain their
existing live feeds.

### 1.3 Subcategories — one named screen each
Per the follow-up instruction, every subcategory has its **own named
screen file** (no generic placeholder class shared across all of them).
Subcategory metadata lives in `lib/data/subcategory_data.dart`; routing
from a subcategory to its screen is centralized in
`lib/screens/subcategory_router.dart` (`openSubcategory()`).

| Form | Subcategories | Live | Screen file(s) |
|---|---|---|---|
| Videos | Long-form, Interviews, Lectures & Tutorials, Documentaries, Webinars & Events | Long-form | `videos_feed_screen.dart` (live); rest in `screens/subcategories/videos/` |
| Shorts | Clips, Quick Explanations, Highlights, Demonstrations | Clips | `channels_screen.dart` (existing, reused, live); rest in `screens/subcategories/shorts/` |
| Audio | Podcasts, Audiobooks, Interviews, Lectures, Audio Courses | — | all in `screens/subcategories/audio/` |
| Written | Books, Blogs, Articles, Research Papers, News & Reports, Newsletters, Case Studies | Books, Blogs | `books_feed_screen.dart`, `blogs_feed_screen.dart` (live); rest in `screens/subcategories/written/` |
| Datasets | Datasets, Statistics, Calculators, Directories | — | all in `screens/subcategories/structured/` |

"Live" = wired to real Rumuo content today (reuses the existing
`FeedProvider` videos/books tabs, or the existing blog/shorts screens —
zero backend changes). Everything else renders a shared, on-brand
**"Coming soon — building this out"** shell
(`lib/widgets/subcategory_placeholder.dart` → `SubcategoryScaffold`) so
the room exists and is navigable, ready for real content as the backend
grows — each is its own file/class, not a shared generic screen, so
content can be dropped into any one of them independently.

### 1.4 Bottom nav
`Shorts` is removed from the bottom nav (Shorts is now a shelf inside
Feed) and **nothing replaced it** — nav is **Feed, Saved, Profile**
(3 tabs). `discover_screen.dart` was left fully untouched.

### 1.5 Auto-hide header / search / bottom nav
While the Feed is scrolling, the header+search block and the bottom nav
collapse away (`AnimatedSize`, driven by
`lib/services/scroll_visibility_service.dart`); both return the moment
scrolling stops. Bottom nav only does this on the Feed tab — it stays
fully visible on Saved/Profile.

### 1.6 CI fix — `flutter analyze` error
First push failed: `scroll_visibility_service.dart` used
`ScrollDirection` without importing `package:flutter/rendering.dart`
directly (it's normally reachable through `material.dart`, but the
analyzer needed it explicit here). Fixed by adding that import. The
other ~76 items in that CI run were pre-existing `info`-level lints in
files this restructure never touched — not a regression.

## 2. New files (18 + 22 subcategory screens = 40)

- `models/information_form.dart`, `models/subcategory.dart`
- `data/subcategory_data.dart`
- `services/scroll_visibility_service.dart`
- `widgets/feed_shelf.dart`, `widgets/subcategory_card.dart`,
  `widgets/subcategory_placeholder.dart`
- `widgets/video_feed_list.dart`, `widgets/books_list.dart` — Videos/Books
  rendering extracted out of the old `home_screen.dart` so both the new
  standalone screens and any future reuse share one implementation
- `screens/videos_feed_screen.dart`, `screens/books_feed_screen.dart`,
  `screens/blogs_feed_screen.dart`
- `screens/subcategory_router.dart`, `screens/information_form_screen.dart`
- `screens/subcategories/{videos,shorts,audio,written,structured}/*.dart`
  (22 dedicated subcategory screens)
- this audit file

## 3. Modified files (2)

- `screens/home_screen.dart` — full rewrite (header/search/shelves/auto-hide)
- `screens/main_shell.dart` — Shorts removed from nav, auto-hide wiring

Verified against your original upload with a full recursive diff —
these are the only files that differ; everything else, including
`discover_screen.dart`, is byte-identical to what you sent.

## 4. Explicitly not touched (per instruction)

`FeedTab`, `FeedProvider`, `ResourceCategory`/taxonomy data, ad service,
notification service, all content-fetching/services. The five
information forms exist today purely as a **frontend organizing layer**
over the existing four backend tabs.

## 5. Suggested next steps (backend, separate pass)

1. Give `Video`/content records a real `subcategoryId` so "Long-form"
   vs "Interviews" vs "Documentaries" etc. can filter instead of all
   pointing at the same general video list.
2. Stand up Audio and Structured/Interactive as real content types —
   currently zero data sources for either.
3. Once subcategory-level data exists, `SubcategoryData.isLive` flags
   flip and the "SOON" badges disappear on their own — no further UI
   change needed.
