import 'dart:typed_data';

/// Fallback for any platform that's neither `dart:io` (Android/iOS/desktop,
/// via `gal`) nor `dart:html`/web (browser download) — shouldn't be hit in
/// practice, but keeps the conditional export exhaustive.
Future<void> saveImageBytes(Uint8List bytes, String fileName) async {
  throw UnsupportedError('Saving images is not supported on this platform.');
}
