import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';

const _prefsKey = 'app_language';

/// Drives the whole app's language: [MaterialApp.locale], the Voice Order
/// feature's speech-recognition locale, and the Settings screen's
/// "Language" row subtitle all read from this one provider, so they can
/// never disagree.
///
/// Starts as English synchronously (the documented default — the app must
/// never flash a different language while a persisted preference loads),
/// then asynchronously checks SharedPreferences for a previously-saved
/// choice and switches over once that resolves, same
/// build-then-Future.microtask pattern already used by HistoryController
/// elsewhere in this app.
class LanguageController extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    Future.microtask(_loadPersisted);
    return AppLanguage.english;
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      state = AppLanguageX.fromCode(saved);
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (state == language) return;
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.code);
  }
}

final languageProvider = NotifierProvider<LanguageController, AppLanguage>(
  LanguageController.new,
);
