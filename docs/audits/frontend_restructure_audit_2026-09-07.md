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
replaced with a **single vertically-scrolling feed** made of five
shelves, one per `InformationForm` (`lib/models/information_form.dart`):

**Videos → Shorts → Audio → Written → Structured/Interactive**

Each shelf (`lib/widgets/feed_shelf.dart`) scrolls its **subcategories
horizontally**, ending in a **"See more"** card. Tapping "See more" (or
the shelf's "See all") opens `InformationFormScreen`
(`lib/screens/information_form_screen.dart`) — a grid of every
subcategory under that form.

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
| Structured | Datasets, Statistics, Calculators, Directories, Interactive Tools | — | all in `screens/subcategories/structured/` |

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
Feed) and replaced with **Discover** — the existing
`DiscoverScreen` (Profession / Skill / Business browser), previously
only reachable indirectly. `DiscoverScreen` gained a `showBackButton`
flag so it renders correctly both as a nav tab (no back arrow) and if
ever pushed as its own route.

### 1.5 Auto-hide header / search / bottom nav
While the Feed is scrolling, the header+search block and the bottom nav
collapse away (`AnimatedSize`, driven by
`lib/services/scroll_visibility_service.dart`); both return the moment
scrolling stops. Bottom nav only does this on the Feed tab — it stays
fully visible on Discover/Saved/Profile.

## 2. New files (37 touched total)

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

## 3. Modified files

- `screens/home_screen.dart` — full rewrite (header/search/shelves/auto-hide)
- `screens/main_shell.dart` — bottom nav swap + auto-hide wiring
- `screens/discover_screen.dart` — added `showBackButton`

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
