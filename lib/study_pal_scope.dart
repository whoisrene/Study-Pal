import 'package:flutter/material.dart';

import 'data/study_pal_store.dart';

class StudyPalScope extends InheritedWidget {
  const StudyPalScope({super.key, required this.store, required super.child});

  final StudyPalStore store;

  static StudyPalStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StudyPalScope>();
    assert(scope != null, 'StudyPalScope not found');
    return scope!.store;
  }

  @override
  bool updateShouldNotify(covariant StudyPalScope oldWidget) {
    return oldWidget.store != store;
  }
}
