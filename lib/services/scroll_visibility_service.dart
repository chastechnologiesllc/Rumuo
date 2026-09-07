import 'package:flutter/material.dart';

/// Drives the show/hide animation of the header, search bar and bottom
/// nav while the feed is scrolling. Mirrors the [NotificationStore]
/// singleton pattern elsewhere in the app — subscribe with a
/// ValueListenableBuilder, no Provider wiring needed.
///
/// Behavior: hides the moment the feed starts moving, shows again the
/// moment it settles — feed the notifications straight from a
/// NotificationListener<ScrollNotification> via [handleScrollNotification].
class ScrollVisibilityService {
  ScrollVisibilityService._();
  static final ScrollVisibilityService instance = ScrollVisibilityService._();

  final ValueNotifier<bool> visible = ValueNotifier<bool>(true);

  void show() {
    if (!visible.value) visible.value = true;
  }

  void hide() {
    if (visible.value) visible.value = false;
  }

  /// Pass straight to `NotificationListener<ScrollNotification>.onNotification`.
  bool handleScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle) {
        show();
      } else {
        hide();
      }
    } else if (notification is ScrollEndNotification) {
      show();
    }
    return false;
  }
}
