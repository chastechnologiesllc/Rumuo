import 'package:flutter/material.dart';

import 'information_form.dart';

/// A subcategory living under one of the five [InformationForm]s — e.g.
/// "Books" and "Blogs" both live under Written. Subcategories are the
/// rooms the product keeps filling with content over time.
///
/// [isLive] marks the subcategories that already have real Rumuo content
/// wired up today (Long-form videos, Clips, Books, Blogs). Everything
/// else opens a prototype placeholder screen — the room exists and is
/// navigable, ready to receive real content as the backend grows.
class Subcategory {
  final String id;
  final String name;
  final InformationForm form;
  final IconData icon;
  final String description;
  final bool isLive;

  const Subcategory({
    required this.id,
    required this.name,
    required this.form,
    required this.icon,
    required this.description,
    this.isLive = false,
  });
}
