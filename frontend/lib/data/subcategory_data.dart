import 'package:flutter/material.dart';

import '../models/information_form.dart';
import '../models/subcategory.dart';

/// Static subcategory list per [InformationForm]. This is prototype-stage
/// data — [Subcategory.isLive] marks the handful already backed by real
/// Rumuo content (Long-form videos, Clips, Books, Blogs); the rest are
/// scaffolded rooms waiting for content as the product is built out.
class SubcategoryData {
  SubcategoryData._();

  static const List<Subcategory> videos = [
    Subcategory(
      id: 'videos_long_form',
      name: 'Long-form',
      form: InformationForm.videos,
      icon: Icons.smart_display_rounded,
      description: 'Full-length videos from every Rumuo channel',
      isLive: true,
    ),
    Subcategory(
      id: 'videos_interviews',
      name: 'Interviews',
      form: InformationForm.videos,
      icon: Icons.record_voice_over_rounded,
      description: 'One-on-one conversations with experts',
    ),
    Subcategory(
      id: 'videos_lectures',
      name: 'Lectures & Tutorials',
      form: InformationForm.videos,
      icon: Icons.school_rounded,
      description: 'Step-by-step teaching and how-tos',
    ),
    Subcategory(
      id: 'videos_documentaries',
      name: 'Documentaries',
      form: InformationForm.videos,
      icon: Icons.movie_filter_rounded,
      description: 'In-depth documentary features',
    ),
    Subcategory(
      id: 'videos_webinars',
      name: 'Webinars & Events',
      form: InformationForm.videos,
      icon: Icons.groups_rounded,
      description: 'Recorded talks and live sessions',
    ),
  ];

  static const List<Subcategory> shorts = [
    Subcategory(
      id: 'shorts_clips',
      name: 'Clips',
      form: InformationForm.shorts,
      icon: Icons.flash_on_rounded,
      description: 'Quick vertical clips from every channel',
      isLive: true,
    ),
    Subcategory(
      id: 'shorts_explanations',
      name: 'Quick Explanations',
      form: InformationForm.shorts,
      icon: Icons.bolt_rounded,
      description: 'Fast, focused explainers',
    ),
    Subcategory(
      id: 'shorts_highlights',
      name: 'Highlights',
      form: InformationForm.shorts,
      icon: Icons.star_rounded,
      description: 'Best moments, pulled out',
    ),
    Subcategory(
      id: 'shorts_demos',
      name: 'Demonstrations',
      form: InformationForm.shorts,
      icon: Icons.build_circle_rounded,
      description: 'Short hands-on demonstrations',
    ),
  ];

  static const List<Subcategory> audio = [
    Subcategory(
      id: 'audio_podcasts',
      name: 'Podcasts',
      form: InformationForm.audio,
      icon: Icons.podcasts_rounded,
      description: 'Episodic audio conversations',
    ),
    Subcategory(
      id: 'audio_audiobooks',
      name: 'Audiobooks',
      form: InformationForm.audio,
      icon: Icons.auto_stories_rounded,
      description: 'Books narrated for listening',
    ),
    Subcategory(
      id: 'audio_interviews',
      name: 'Interviews',
      form: InformationForm.audio,
      icon: Icons.mic_rounded,
      description: 'Audio-only expert interviews',
    ),
    Subcategory(
      id: 'audio_lectures',
      name: 'Lectures',
      form: InformationForm.audio,
      icon: Icons.school_rounded,
      description: 'Recorded spoken lectures',
    ),
    Subcategory(
      id: 'audio_courses',
      name: 'Audio Courses',
      form: InformationForm.audio,
      icon: Icons.library_music_rounded,
      description: 'Structured audio learning',
    ),
  ];

  static const List<Subcategory> written = [
    Subcategory(
      id: 'written_books',
      name: 'Books',
      form: InformationForm.written,
      icon: Icons.menu_book_rounded,
      description: 'Free books and eBooks',
      isLive: true,
    ),
    Subcategory(
      id: 'written_blogs',
      name: 'Blogs',
      form: InformationForm.written,
      icon: Icons.rss_feed_rounded,
      description: 'Articles from trusted blogs',
      isLive: true,
    ),
    Subcategory(
      id: 'written_articles',
      name: 'Articles',
      form: InformationForm.written,
      icon: Icons.article_rounded,
      description: 'Standalone written pieces',
    ),
    Subcategory(
      id: 'written_papers',
      name: 'Research Papers',
      form: InformationForm.written,
      icon: Icons.description_rounded,
      description: 'Academic and professional research',
    ),
    Subcategory(
      id: 'written_news',
      name: 'News & Reports',
      form: InformationForm.written,
      icon: Icons.newspaper_rounded,
      description: 'Current developments and reports',
    ),
    Subcategory(
      id: 'written_newsletters',
      name: 'Newsletters',
      form: InformationForm.written,
      icon: Icons.mail_rounded,
      description: 'Recurring written updates',
    ),
    Subcategory(
      id: 'written_cases',
      name: 'Case Studies',
      form: InformationForm.written,
      icon: Icons.fact_check_rounded,
      description: 'Real-world breakdowns and lessons',
    ),
  ];

  static const List<Subcategory> structured = [
    Subcategory(
      id: 'structured_datasets',
      name: 'Datasets',
      form: InformationForm.structured,
      icon: Icons.storage_rounded,
      description: 'Structured data to explore',
    ),
    Subcategory(
      id: 'structured_statistics',
      name: 'Statistics',
      form: InformationForm.structured,
      icon: Icons.bar_chart_rounded,
      description: 'Figures, trends and benchmarks',
    ),
    Subcategory(
      id: 'structured_calculators',
      name: 'Calculators',
      form: InformationForm.structured,
      icon: Icons.calculate_rounded,
      description: 'Interactive problem-solving tools',
    ),
    Subcategory(
      id: 'structured_directories',
      name: 'Directories',
      form: InformationForm.structured,
      icon: Icons.map_rounded,
      description: 'Organizations, people & places',
    ),
    Subcategory(
      id: 'structured_tools',
      name: 'Interactive Tools',
      form: InformationForm.structured,
      icon: Icons.widgets_rounded,
      description: 'Simulations and hands-on tools',
    ),
  ];

  static List<Subcategory> forForm(InformationForm form) => switch (form) {
        InformationForm.videos => videos,
        InformationForm.shorts => shorts,
        InformationForm.audio => audio,
        InformationForm.written => written,
        InformationForm.structured => structured,
      };
}
