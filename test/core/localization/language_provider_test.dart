import 'package:flutter_application_1/core/localization/app_language.dart';
import 'package:flutter_application_1/core/localization/language_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to English before any persisted value loads', () {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(languageProvider), AppLanguage.english);
  });

  test('setLanguage updates state immediately and persists the choice', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(languageProvider.notifier).setLanguage(AppLanguage.hindi);

    expect(container.read(languageProvider), AppLanguage.hindi);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_language'), 'hi');
  });

  test('a previously-persisted Hindi choice is picked up on next launch', () async {
    SharedPreferences.setMockInitialValues({'app_language': 'hi'});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // build() returns English synchronously first (never flashes a
    // different language while the persisted value loads), then switches
    // once the async SharedPreferences read resolves.
    expect(container.read(languageProvider), AppLanguage.english);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(languageProvider), AppLanguage.hindi);
  });
}
