import 'dart:typed_data';

/// A file picked (and validated) locally, before upload.
class SelectedDocument {
  const SelectedDocument({
    required this.fileName,
    required this.bytes,
    required this.sizeInBytes,
    required this.mimeType,
  });

  final String fileName;
  final Uint8List bytes;
  final int sizeInBytes;
  final String mimeType;
}
