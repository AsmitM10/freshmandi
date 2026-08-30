import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Opens the platform's native share sheet with a generated PNG — on Web
/// this is `navigator.share`, which already lets the person pick WhatsApp,
/// SMS, or anything else installed, so there's no separate per-channel
/// integration to build for those.
Future<void> shareImageBytes(
  Uint8List bytes,
  String fileName, {
  String? text,
}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(bytes, name: '$fileName.png', mimeType: 'image/png'),
      ],
      text: text,
    ),
  );
}

/// Same idea as [shareImageBytes] but for a generated PDF (see
/// `pdf_export.dart`).
Future<void> sharePdfBytes(
  Uint8List bytes,
  String fileName, {
  String? text,
}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          bytes,
          name: '$fileName.pdf',
          mimeType: 'application/pdf',
        ),
      ],
      text: text,
    ),
  );
}
