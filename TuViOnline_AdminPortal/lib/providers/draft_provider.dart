import 'package:flutter/material.dart';
import '../models/forum_category_model.dart';

class DraftProvider extends ChangeNotifier {
  final List<ForumCategoryItem> _drafts = [];

  List<ForumCategoryItem> get drafts => List.unmodifiable(_drafts);

  void addDraft(ForumCategoryItem draft) {
    _drafts.insert(0, draft);
    notifyListeners();
  }

  void removeDraft(int index) {
    if (index >= 0 && index < _drafts.length) {
      _drafts.removeAt(index);
      notifyListeners();
    }
  }

  void clearDrafts() {
    _drafts.clear();
    notifyListeners();
  }
}
