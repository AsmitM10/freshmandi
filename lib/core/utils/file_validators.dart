import 'dart:typed_data';

import '../constants/app_config.dart';

class FileValidationResult {
  const FileValidationResult.valid(this.mimeType)
    : isValid = true,
      errorMessage = null;

  const FileValidationResult.invalid(this.errorMessage)
    : isValid = false,
      mimeType = null;

  final bool isValid;
  final String? mimeType;
  final String? errorMessage;
}

/// Validates the FSSAI certificate upload: existence, size, and actual file
/// content (magic-byte sniffing) rather than trusting the file extension,
/// which can be spoofed. Extension-based MIME lookup is not enough on its own.
class FileValidators {
  FileValidators._();

  static const Map<String, List<int>> _magicBytes = {
    'application/pdf': [0x25, 0x50, 0x44, 0x46], // %PDF
    'image/png': [0x89, 0x50, 0x4E, 0x47],
    'image/jpeg': [0xFF, 0xD8, 0xFF],
  };

  static FileValidationResult validate({
    required Uint8List? bytes,
    required int? sizeInBytes,
  }) {
    if (bytes == null || bytes.isEmpty) {
      return const FileValidationResult.invalid('Please select a file');
    }

    final size = sizeInBytes ?? bytes.length;
    if (size > AppConfig.fssaiMaxSizeBytes) {
      return const FileValidationResult.invalid('File is larger than 2 MB');
    }
    if (size <= 0) {
      return const FileValidationResult.invalid('File appears to be empty');
    }

    final sniffed = _sniff(bytes);
    if (sniffed == null) {
      return const FileValidationResult.invalid(
        'Only PDF, JPG, JPEG or PNG files are supported',
      );
    }

    return FileValidationResult.valid(sniffed);
  }

  static String? _sniff(Uint8List bytes) {
    for (final entry in _magicBytes.entries) {
      if (_startsWith(bytes, entry.value)) return entry.key;
    }
    return null;
  }

  static bool _startsWith(Uint8List bytes, List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }
}
