import 'package:flutter/material.dart';

/// The five primary information forms Rumuo organizes discovery around —
/// containers for knowledge, not separate products or silos. Each form
/// holds a set of [Subcategory] "rooms" (see subcategory_data.dart).
///
/// Mirrors the founder's documents (#2 Product Architecture, #3 Feed
/// Philosophy): Video, Shorts, Audio, Written, Structured/Interactive.
enum InformationForm {
  videos,
  shorts,
  audio,
  written,
  structured,
}

extension InformationFormX on InformationForm {
  String get label => switch (this) {
        InformationForm.videos => 'Videos',
        InformationForm.shorts => 'Shorts',
        InformationForm.audio => 'Audio',
        InformationForm.written => 'Written',
        InformationForm.structured => 'Datasets & Tools',
      };

  /// One-line description shown under each shelf header.
  String get tagline => switch (this) {
        InformationForm.videos =>
          'Long-form videos, interviews, lectures & documentaries',
        InformationForm.shorts =>
          'Quick clips, highlights & concise explanations',
        InformationForm.audio => 'Podcasts, audiobooks & spoken knowledge',
        InformationForm.written =>
          'Books, blogs, articles, papers & reports',
        InformationForm.structured =>
          'Datasets, statistics, calculators, directories & interactive tools',
      };

  IconData get icon => switch (this) {
        InformationForm.videos => Icons.smart_display_rounded,
        InformationForm.shorts => Icons.flash_on_rounded,
        InformationForm.audio => Icons.headphones_rounded,
        InformationForm.written => Icons.menu_book_rounded,
        InformationForm.structured => Icons.widgets_rounded,
      };
}
