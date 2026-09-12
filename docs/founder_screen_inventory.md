# Rumuo Founder Screen Inventory

This inventory maps the founder documents to the current frontend. The documents describe product capabilities and user surfaces rather than a fixed route list, so the mapping separates **already implemented screens**, **implemented in this pass**, and **future backend-dependent surfaces**. Existing screens are not reworked unless explicitly requested.

## Required product surfaces

| Founder-derived surface | Evidence | Current status | Frontend decision |
|---|---|---|---|
| Feed / personalized discovery | Documents 2, 3, 11 | Exists through `MainShell`, `HomeScreen`, and feed screens | Leave unchanged |
| Five information-form feeds: Video, Shorts, Audio, Text, Data | Documents 2, 3, 4, 5 | Exists through feed/subcategory routing; primary labels were previously corrected to Text and Data | Leave unchanged |
| Search and autocomplete | Documents 4, 10, 11, 13 | Exists through `ContentSearchScreen`, platform index, sessions, and search tools | Leave unchanged |
| Deep research / research sessions | Documents 4, 10, 11, 12, 13 | Partial frontend foundation exists through search sessions and tools | Leave unchanged; backend orchestration is not part of this frontend-only pass |
| Resource detail and provenance | Documents 5, 9, 11 | Exists through video, book, blog, and category detail screens | Leave unchanged |
| Category / profession / skill / business entry points | Documents 2, 8, 11 | Exists through category and My Business screens | Leave unchanged |
| Saved resources / bookmarks | Documents 3, 11, 13 | Exists through `SavedScreen` | Leave unchanged |
| Channels / creators / source discovery | Documents 5, 7, 9, 14 | Exists through channel and blog-channel screens | Leave unchanged |
| Account creation and login | Documents 11 and 13 | Exists through `AuthScreen` | Only requested change: Apple icon increased |
| Profile and personalization | Documents 3, 11, 13 | Exists through `ProfileScreen` and `MyBusinessScreen` | Added navigation only for the newly missing Settings and Plans surfaces |
| Notifications and notification preferences | Documents 3, 11 | Exists through notifications and notification settings screens | Leave unchanged |
| Privacy, terms, disclaimer, support | Documents 9, 13, 16 | Exists through legal and support screens | Leave unchanged |
| **Settings / privacy control center** | Documents 11 and 13: reset personalization, delete research history, private search, user controls, data boundaries | **Missing as a dedicated screen** | **Created `SettingsScreen`** |
| **Monetization / plans** | Document 12: free discovery, Pro/deep research, enterprise intelligence, premium data and research products | **Missing** | **Created `MonetizationScreen`** |

## Deliberately not fabricated in this frontend pass

The founder documents also describe enterprise workspaces, monitored research, alerts, premium datasets, referral transactions, contextual advertising, source governance tooling, acquisition dashboards, knowledge-graph administration, and API/intelligence infrastructure. These require backend data, permissions, billing, or operational workflows. They should become separate screens when their contracts exist; they are not represented as fake consumer flows in this pass.

## Changes made in this pass

The Apple provider mark on the authentication screen was increased from 28px to 34px while staying inside the existing provider-button layout. A dedicated Settings screen was added with frontend-only controls for personalization, private search, research history deletion, data saver, and account-state messaging. A dedicated Rumuo plans screen was added with free discovery, Pro research, and enterprise intelligence surfaces based on the founder economic model; its actions clearly indicate that billing is not connected yet. The existing Profile screen was only extended with entry points to these newly requested surfaces.
