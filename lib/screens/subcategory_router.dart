import 'package:flutter/material.dart';

import '../models/subcategory.dart';
import 'blogs_feed_screen.dart';
import 'books_feed_screen.dart';
import 'channels_screen.dart';
import 'subcategories/audio/audio_courses_screen.dart';
import 'subcategories/audio/audio_interviews_screen.dart';
import 'subcategories/audio/audio_lectures_screen.dart';
import 'subcategories/audio/audiobooks_screen.dart';
import 'subcategories/audio/podcasts_screen.dart';
import 'subcategories/shorts/demonstrations_screen.dart';
import 'subcategories/shorts/highlights_screen.dart';
import 'subcategories/shorts/quick_explanations_screen.dart';
import 'subcategories/structured/calculators_screen.dart';
import 'subcategories/structured/datasets_screen.dart';
import 'subcategories/structured/directories_screen.dart';
import 'subcategories/structured/interactive_tools_screen.dart';
import 'subcategories/structured/statistics_screen.dart';
import 'subcategories/videos/documentaries_screen.dart';
import 'subcategories/videos/lectures_tutorials_screen.dart';
import 'subcategories/videos/video_interviews_screen.dart';
import 'subcategories/videos/webinars_events_screen.dart';
import 'subcategories/written/articles_screen.dart';
import 'subcategories/written/case_studies_screen.dart';
import 'subcategories/written/news_reports_screen.dart';
import 'subcategories/written/newsletters_screen.dart';
import 'subcategories/written/research_papers_screen.dart';
import 'videos_feed_screen.dart';

/// Central route table for every named subcategory across the five
/// shelves. Every subcategory — live or prototype — has its own named
/// screen file (see lib/screens/subcategories/); this is the one place
/// that wires a subcategory id to the screen it opens, so a new
/// subcategory only ever needs a new entry here.
void openSubcategory(BuildContext context, Subcategory subcategory) {
  final screen = _screenFor(subcategory);
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

Widget _screenFor(Subcategory subcategory) {
  switch (subcategory.id) {
    // ── Videos ──────────────────────────────────────────────────────
    case 'videos_long_form':
      return const VideosFeedScreen();
    case 'videos_interviews':
      return const VideoInterviewsScreen();
    case 'videos_lectures':
      return const LecturesTutorialsScreen();
    case 'videos_documentaries':
      return const DocumentariesScreen();
    case 'videos_webinars':
      return const WebinarsEventsScreen();

    // ── Shorts ──────────────────────────────────────────────────────
    case 'shorts_clips':
      return const ChannelsScreen();
    case 'shorts_explanations':
      return const QuickExplanationsScreen();
    case 'shorts_highlights':
      return const HighlightsScreen();
    case 'shorts_demos':
      return const DemonstrationsScreen();

    // ── Audio ───────────────────────────────────────────────────────
    case 'audio_podcasts':
      return const PodcastsScreen();
    case 'audio_audiobooks':
      return const AudiobooksScreen();
    case 'audio_interviews':
      return const AudioInterviewsScreen();
    case 'audio_lectures':
      return const AudioLecturesScreen();
    case 'audio_courses':
      return const AudioCoursesScreen();

    // ── Written ─────────────────────────────────────────────────────
    case 'written_books':
      return const BooksFeedScreen();
    case 'written_blogs':
      return const BlogsFeedScreen();
    case 'written_articles':
      return const ArticlesScreen();
    case 'written_papers':
      return const ResearchPapersScreen();
    case 'written_news':
      return const NewsReportsScreen();
    case 'written_newsletters':
      return const NewslettersScreen();
    case 'written_cases':
      return const CaseStudiesScreen();

    // ── Structured / Interactive ────────────────────────────────────
    case 'structured_datasets':
      return const DatasetsScreen();
    case 'structured_statistics':
      return const StatisticsScreen();
    case 'structured_calculators':
      return const CalculatorsScreen();
    case 'structured_directories':
      return const DirectoriesScreen();
    case 'structured_tools':
      return const InteractiveToolsScreen();

    default:
      // Should be unreachable as long as every SubcategoryData entry has
      // a case above — kept as a safe fallback rather than a crash.
      return Scaffold(
        appBar: AppBar(title: Text(subcategory.name)),
        body: Center(child: Text('${subcategory.name} is on its way.')),
      );
  }
}
