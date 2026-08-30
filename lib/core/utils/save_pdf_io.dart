import 'dart:typed_data';

/// Android/iOS/desktop — unlike an image, a PDF has no photo-gallery
/// equivalent to save into (see `save_image_io.dart`'s use of `gal`), so
/// there's no direct-write fallback here. In practice this is only ever
/// reached if the share sheet itself hangs, which is a desktop-web
/// `navigator.share()` quirk, not something observed on native — sharing
/// (not this fallback) is the supported path on this platform.
Future<void> savePdfBytes(Uint8List bytes, String fileName) async {
  throw UnsupportedError(
    'Saving a PDF directly is not supported on this platform — use the share sheet instead.',
  );
}
