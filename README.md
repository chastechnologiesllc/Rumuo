# Rumuo

**A knowledge discovery platform for the worlds people want to understand, build, and navigate.**

Rumuo is being built by **chAs Technologies LLC** as a cross-format discovery system for professions, skills, businesses, opportunities, and the questions around them. The product begins with a focused Flutter experience for videos, Shorts, blogs, and books, while its long-term architecture is designed to connect the wider knowledge ecosystem around a person’s intent.

> **Our founding belief:** The world already contains an enormous amount of knowledge. Rumuo’s job is to make the right knowledge discoverable, understandable, connected, and useful to the person looking for it.

## Why Rumuo exists

Useful knowledge is scattered across videos, books, articles, podcasts, research, reports, tools, experts, institutions, and archives. People often have to search many disconnected systems before they can understand a field or solve one meaningful problem.

Rumuo exists to reduce that fragmentation. A person should be able to enter a profession, skill, business, opportunity, or area of curiosity and discover the knowledge ecosystem around it without already knowing where that knowledge lives.

Rumuo is therefore built around **discovery rather than simple consumption**. We do not need to own every piece of knowledge. We need to help people find, navigate, connect, compare, and research the knowledge that already exists.

## Product model

Rumuo’s enduring product model is:

```text
Person + Intent
      ↓
Knowledge Universe
      ↓
Sources → Resources → Discovery
      ↓
Research → Understanding → New Questions
```

A category is not a rigid course or a folder. It is a **knowledge universe** around a profession, skill, business, opportunity, or other meaningful field. Within that universe may be education, practical knowledge, professional practice, business, research, technology, careers, current developments, experts, organizations, tools, and adjacent knowledge.

The core user journey is:

```text
Choose a world → discover resources → search a question → connect related knowledge
→ go deeper → save useful findings → return and continue researching
```

## One discovery system, many information forms

Rumuo treats formats as different ways knowledge is presented—not as isolated products.

| Information form | Examples | Current product surface |
|---|---|---|
| **Video** | Tutorials, lectures, interviews, demonstrations, documentaries, webinars | Implemented through the video feed and player experience |
| **Shorts** | Clips, highlights, concise explanations, quick demonstrations | Implemented through Shorts detection and discovery |
| **Audio** | Podcasts, audiobooks, interviews, recorded lectures, discussions | Long-term product direction |
| **Written** | Books, eBooks, blogs, articles, papers, reports, documentation | Implemented through blogs and books |
| **Structured / interactive** | Datasets, maps, statistics, calculators, simulations, directories, knowledge graphs | Long-term product direction |

The same research problem may require several forms at once. Someone investigating how to build a successful clinic could need an interview video, a podcast, healthcare-management books, patient-acquisition articles, regulatory documents, market reports, and relevant statistics. Rumuo’s architecture is intended to connect those resources around the underlying question.

## Discovery feed

The feed is intended to be a **personalized stream of discoveries**, not an entertainment feed optimized only for scrolling or watch time. Its guiding question is:

> **What is worth discovering for this person right now?**

Over time, useful ranking signals include:

- Selected professions, skills, businesses, opportunities, and topics.
- Current searches and active research intent.
- Resources opened, watched, read, saved, skipped, dismissed, or revisited.
- Completion, continued research, and movement into related resources.
- Source credibility, provenance, evidence, freshness, and contextual authority.
- Format preference without hiding important knowledge in other formats.
- Diversity across sources, creators, perspectives, and information forms.
- Adjacent discoveries that may materially help the person’s goal.

Rumuo should support several intent states without permanently trapping a person in one profile:

| Intent | The user is asking… | Discovery emphasis |
|---|---|---|
| **Explore** | “Show me interesting things around my field.” | Novelty and adjacent topics |
| **Learn** | “Help me understand this topic.” | Explanatory and foundational resources |
| **Research** | “I need to investigate this question.” | Evidence, depth, and cross-format resources |
| **Solve** | “I have this specific problem.” | Practical resources, tools, examples, and solutions |
| **Keep current** | “What has changed?” | Fresh news, updates, reports, and current sources |
| **Build / achieve** | “I am trying to make something happen.” | Practical knowledge, case studies, experts, and tools |

**Attention is a signal, not the final objective.** A long book, official report, lecture, podcast segment, or dataset may be more useful than the most entertaining item.

## Search and deep research

Search is a primary entrance into Rumuo’s knowledge system. The long-term ambition is not merely to return a short answer, but to understand what a person is trying to accomplish and connect that intent to useful, inspectable knowledge.

The intended search pipeline is:

```text
Question → Intent → Concepts → Candidate resources → Ranking
→ Evidence and context → Related discoveries
```

For complex questions, deep research should:

1. Understand the question, context, and likely objective.
2. Identify whether the person wants to learn, compare, solve, research, verify, build, buy, or keep current.
3. Expand the question into related terms, entities, subtopics, synonyms, and adjacent concepts.
4. Retrieve across video, Shorts, audio, written, and structured resources.
5. Evaluate relevance, quality, provenance, freshness, diversity, and evidence.
6. Connect resources by the questions and concepts they address.
7. Present the strongest discoveries first while preserving paths into deeper research.

AI may help organize a research problem, compare sources, extract relationships, and identify gaps. **The underlying resources must remain visible, inspectable, and discoverable.** Rumuo is not intended to replace evidence with unsupported AI confidence.

## Trust, provenance, and source governance

Trust is contextual rather than a permanent label. A source may be authoritative for one claim, jurisdiction, profession, or point in time and less useful for another. Rumuo’s trust model is intended to keep the following dimensions separate:

- **Authority:** who produced the resource and what they are qualified to address.
- **Evidence:** what supports the claim and whether the support is inspectable.
- **Relevance:** whether it addresses the person’s actual intent.
- **Freshness:** whether it is current enough for the domain.
- **Context:** geography, profession, industry, audience, time, and conditions.
- **Consistency:** how it relates to other credible sources.
- **Verification:** how much has actually been checked.
- **Access:** whether the resource is publicly accessible, restricted, or unavailable.

Rumuo should preserve provenance from creator or author through publisher and original location to publication or update time, acquisition path, indexing decisions, and verification history.

> **Popularity is not truth. User usefulness is not factual correctness.** User signals can improve discovery and relevance; evidence, provenance, verification, and authoritative sources must govern factual trust.

When credible sources disagree, Rumuo should preserve the disagreement and expose the relevant context rather than manufacture certainty. High-impact, ambiguous, sensitive, or conflicting cases should support human review alongside automated extraction and comparison.

## Knowledge model and long-term architecture

Every indexed resource is intended to become a structured knowledge object with:

| Layer | Examples |
|---|---|
| **Identity** | Title, creator, author, publisher, source, canonical location |
| **Format** | Video, Short, Audio, Written, Structured / Interactive |
| **Knowledge** | Category, topic, subtopic, concepts, questions answered |
| **Context** | Profession, skill, business, geography, audience, level |
| **Trust** | Provenance, verification, source reputation, evidence |
| **Time** | Published date, update date, freshness, expiration where relevant |
| **Relationships** | Related resources, experts, organizations, concepts, questions |
| **Behavior** | Opens, saves, completion, dismissals, searches, feedback |

The platform should gradually develop a source and knowledge graph connecting relationships such as:

- Expert → field → topics → resources.
- Organization → publications → products → research → people.
- Question → concepts → resources.
- Resource → related resources → supporting evidence.
- Topic → current developments → historical foundations.

The durable advantage is not a content count or a badge. It is the accumulated graph of source identities, provenance, verification history, domain-specific authority, freshness, contradictions, corrections, access states, and usefulness signals.

## Current application

The current Rumuo application is a Flutter project organized under [`frontend/`](frontend/). It currently provides:

- A system-adaptive light and dark interface.
- Video and Shorts discovery with YouTube RSS-based feeds.
- Blog and written-resource discovery.
- A books and playbooks experience with bundled assets and online resources.
- A 60-category starting taxonomy across **Skills**, **Businesses**, and **Professions**.
- Category-focused discovery, search, saved bookmarks, and content detail screens.
- Local deterministic catalog data to provide a useful first frame and stable fallback experience.
- Connectivity checks and graceful offline or unavailable-feed behavior.
- User profile and engagement services that can support future personalization.
- Background service and local notification foundations.
- Cross-platform host projects for Android, iOS, and web.

The current app is the beginning of the broader Rumuo discovery system. Audio, structured/interactive resources, richer provenance, research sessions, and deeper AI-assisted discovery are part of the long-term direction and should be introduced without fragmenting the underlying knowledge model.

## Repository structure

```text
Rumuo/
├── frontend/
│   ├── lib/
│   │   ├── config/          ← app and environment configuration
│   │   ├── data/            ← categories, channels, books, and catalog data
│   │   ├── models/          ← videos, channels, resources, and bookmarks
│   │   ├── providers/       ← feed and application state
│   │   ├── screens/         ← discovery, feeds, readers, settings, and details
│   │   ├── services/        ← RSS, search, notifications, caching, and profiles
│   │   ├── theme/           ← adaptive application theme
│   │   ├── utils/            ← platform and category utilities
│   │   ├── widgets/         ← reusable interface components
│   │   └── main.dart
│   ├── android/             ← Android host project
│   ├── ios/                 ← iOS host project
│   ├── web/                 ← Web host project
│   ├── assets/              ← icons, sounds, books, and blog assets
│   ├── test/                ← Flutter tests
│   ├── analysis_options.yaml
│   └── pubspec.yaml
├── .github/workflows/       ← Android, iOS, and web CI
├── CHANGES.md
├── README.md
└── .gitignore
```

## Technology

- **Flutter / Dart** for the cross-platform application.
- **Provider** for application state and feed coordination.
- **HTTP and XML** for RSS and remote resource access.
- **Shared Preferences and Hive** for local state and reading progress.
- **Workmanager and local notifications** for background refresh foundations.
- **WebView, PDF, EPUB, HTML, and media packages** for cross-format resource experiences.
- **Android, iOS, and Web** host projects maintained under `frontend/`.

## Development

Flutter commands must be run from the `frontend` directory:

```bash
cd frontend
flutter pub get
flutter analyze lib --no-fatal-infos --no-fatal-warnings
flutter test
```

Run the application on a connected device or emulator with:

```bash
cd frontend
flutter run
```

Build individual targets locally with:

```bash
cd frontend
flutter build apk --release --target lib/main.dart
flutter build ios --release --target lib/main.dart --no-codesign
flutter build web --release --target lib/main.dart --base-href "/Rumuo/"
```

## Continuous integration

GitHub Actions run from the `frontend` Flutter project root on pushes and pull requests targeting `main` or `master`:

| Workflow | Purpose |
|---|---|
| [Build Android](.github/workflows/build_andriod.yml) | Analyze, test, build the release APK and AAB, and publish artifacts |
| [Build iOS](.github/workflows/build_ios.yml) | Analyze, test, configure iOS, and compile without signing |
| [Build Web](.github/workflows/build_web.yml) | Analyze, test, build the release web app, upload an artifact, and deploy GitHub Pages from the main branch |

The production Android workflow expects these repository secrets for signed builds:

- `KEYSTORE_BASE64`
- `KEYSTORE_STORE_PASSWORD`
- `KEYSTORE_KEY_ALIAS`
- `KEYSTORE_KEY_PASSWORD`

The iOS workflow currently compiles without signing. Any future distribution-signing workflow should keep certificates and provisioning data in GitHub Actions secrets and never commit them to the repository.

## Product principles

1. **Discovery over consumption:** help people find and navigate useful knowledge, not merely maximize time spent.
2. **Problem before content:** organize resources around what a person is trying to understand or accomplish.
3. **One system across formats:** video, Shorts, audio, written, and structured resources belong to one knowledge model.
4. **Evidence before confidence:** AI can assist organization and research, but sources and provenance remain visible.
5. **Popularity is not truth:** engagement can inform usefulness, never factual correctness by itself.
6. **Context matters:** authority, freshness, geography, audience, and intent change what is useful.
7. **Personalization without entrapment:** learn a person’s context while preserving exploration and diversity.
8. **Global by architecture:** build a system capable of representing many countries, languages, fields, and realities from the beginning.
9. **Human judgment for high-impact trust decisions:** automation handles scale; people handle ambiguity, conflict, and sensitive cases.
10. **Compounding knowledge infrastructure:** every verified source, relationship, correction, and research outcome should make the system more useful over time.

## Status

Rumuo is an actively evolving product. The Flutter application and its current discovery surfaces are under development while the broader knowledge, research, trust, and global architecture mature around the same founding principles.

## License and ownership

Rumuo is proprietary software by **chAs Technologies LLC**. No license to copy, distribute, modify, or commercially use this code is granted unless explicitly provided in writing by the owner.
