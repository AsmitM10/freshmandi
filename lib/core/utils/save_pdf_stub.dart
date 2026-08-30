import 'dart:typed_data';

/// Fallback for any platform that's neither `dart:io` nor web — shouldn't
/// be hit in practice, but keeps the conditional export exhaustive.
Future<void> savePdfBytes(Uint8List bytes, String fileName) async {
  throw UnsupportedError('Saving a PDF is not supported on this platform.');
}
