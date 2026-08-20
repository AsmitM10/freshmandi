import 'package:flutter_application_1/core/localization/app_language.dart';
import 'package:flutter_application_1/features/voice/domain/voice_order_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromCode round-trips through code for both languages', () {
    expect(AppLanguageX.fromCode('en'), AppLanguage.english);
    expect(AppLanguageX.fromCode('hi'), AppLanguage.hindi);
  });

  test('fromCode falls back to English for null/unknown codes', () {
    expect(AppLanguageX.fromCode(null), AppLanguage.english);
    expect(AppLanguageX.fromCode('mr'), AppLanguage.english);
  });

  test('locale matches the persisted code', () {
    expect(AppLanguage.english.locale.languageCode, 'en');
    expect(AppLanguage.hindi.locale.languageCode, 'hi');
  });

  test('app language maps to the matching speech-recognition locale', () {
    expect(VoiceRecognitionLanguageX.fromAppLanguage(AppLanguage.english).localeId, 'en_IN');
    expect(VoiceRecognitionLanguageX.fromAppLanguage(AppLanguage.hindi).localeId, 'hi_IN');
  });
}
